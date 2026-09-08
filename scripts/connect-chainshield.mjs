#!/usr/bin/env node
// Connection preparation only; this is not the #1470 application E2E gate.
import { spawnSync } from 'node:child_process';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const token = process.env.CHAINSHIELD_TM1470_API_KEY;
if (!token || /[\s]/.test(token)) throw new Error('Provide CHAINSHIELD_TM1470_API_KEY through the environment.');
const format = process.argv[2] ?? 'inspect';
if (!['inspect', 'conan', 'swift', 'cocoapods'].includes(format)) throw new Error('Use inspect, conan, swift, or cocoapods.');
const repoType = process.argv[3] ?? 'group';
if (!['hosted', 'group'].includes(repoType)) throw new Error('Use hosted or group for native internal-package consumption.');
const base = 'https://chainshield.cywell.co.kr';
const sourceCommit = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
const sourceDirty = spawnSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' }).stdout.trim() !== '';
if (sourceDirty) throw new Error('Commit connection preparation before running against the registry.');
const run = mkdtempSync(join(tmpdir(), `tonemate-connect-${format}-`));
const repoKey = `tm1470-${format}-${repoType}`;
const endpoint = `${base}/${format}/${repoKey}`;
const summary = { purpose: 'connection-preflight', sourceCommit, sourceDirty, format, repoKey, run, startedAt: new Date().toISOString(), checks: [] };
const secrets = [token, Buffer.from(`chainshield:${token}`).toString('base64')];
const redact = (value) => secrets.reduce((text, secret) => text.replaceAll(secret, '[REDACTED]'), String(value));
const save = (path, value) => writeFileSync(path, JSON.stringify(value, null, 2) + '\n', { mode: 0o600 });
let counter = 0;
function command(program, args, options = {}) {
  const result = spawnSync(program, args, {
    cwd: run, env: { ...process.env, LANG: 'en_US.UTF-8', LC_ALL: 'en_US.UTF-8', ...options.env },
    encoding: 'utf8', timeout: 180000, maxBuffer: 8 * 1024 * 1024, ...options,
  });
  const output = redact((result.stdout ?? '') + (result.stderr ?? '') + (result.error ? '\n' + result.error.message : ''));
  const log = `${++counter}-${program.split('/').at(-1)}.log`;
  writeFileSync(join(run, log), output, { mode: 0o600 });
  summary.checks.push({ command: [program, ...args], exitCode: result.status, log });
  console.log(`${program.split('/').at(-1)} ${args[0] ?? ''}: exit ${result.status}`);
  console.log(output.slice(-5000));
  if (result.status !== 0) throw new Error(`Command failed; see ${join(run, log)}`);
  return output;
}
async function get(path) {
  const response = await fetch(base + path, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(30000) });
  const text = redact(await response.text());
  let body; try { body = JSON.parse(text); } catch { body = text; }
  const result = { path, status: response.status, requestId: response.headers.get('x-request-id'), body };
  summary.checks.push(result);
  return result;
}
try {
  if (format === 'inspect') {
    const repositories = await get('/api/v1/repositories?page_size=100&q=tm1470');
    console.log(JSON.stringify(repositories, null, 2));
    for (const type of ['conan', 'swift', 'cocoapods']) {
      const packages = await get(`/api/v1/repositories/tm1470-${type}-hosted/packages?page_size=100`);
      console.log(JSON.stringify(packages, null, 2));
    }
  } else {
    const consumer = join(run, 'consumer');
    cpSync(join(root, 'qa/chainshield/consumers', format), consumer, { recursive: true });
    const config = join(run, 'config');
    mkdirSync(config, { mode: 0o700 });
    const netrc = join(config, '.netrc');
    writeFileSync(netrc, `machine chainshield.cywell.co.kr login chainshield password ${token}\n`, { mode: 0o600 });
    if (format === 'conan') {
      const conan = process.env.TONEMATE_CONAN ?? join(homedir(), '.local/share/chainshield-tools/conan-2.31.1/bin/conan');
      const env = { ...process.env, CONAN_HOME: join(run, 'conan-home'), CONAN_LOGIN_USERNAME: 'chainshield', CONAN_PASSWORD: token, LANG: 'en_US.UTF-8', LC_ALL: 'en_US.UTF-8' };
      const invoke = (...args) => command(conan, args, { cwd: consumer, env });
      invoke('--version');
      invoke('profile', 'detect');
      invoke('remote', 'add', repoKey, endpoint);
      invoke('remote', 'login', repoKey);
      invoke('install', '.', '-r', repoKey, '--build=never', '-s', 'build_type=Release', '-s', 'compiler.cppstd=20', '-of', 'build');
      invoke('lock', 'create', '.', '-r', repoKey, '-s', 'build_type=Release', '-s', 'compiler.cppstd=20');
      command('cmake', ['-S', '.', '-B', 'build', '-DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake', '-DCMAKE_BUILD_TYPE=Release'], { cwd: consumer });
      command('cmake', ['--build', 'build'], { cwd: consumer });
      command(join(consumer, 'build/tonemate_registry_connection'), []);
    } else if (format === 'swift') {
      command('swift', ['--version']);
      command('swift', ['package-registry', '--config-path', config, 'set', '--global', endpoint]);
      save(join(config, 'registries.json'), { authentication: { 'chainshield.cywell.co.kr': { type: 'basic' } }, registries: { '[default]': { supportsAvailability: false, url: endpoint } }, version: 1 });
      // SwiftPM registry authentication on macOS requires --netrc to choose
      // this credential provider; --disable-keychain alone only affects SCM.
      const options = ['--package-path', consumer, '--config-path', config, '--cache-path', join(run, 'swift-cache'), '--security-path', join(run, 'swift-security'), '--netrc', '--netrc-file', netrc, '--disable-keychain'];
      command('swift', ['package', ...options, 'resolve']);
      command('swift', ['run', ...options, 'ToneMateRegistryConnection']);
      summary.resolved = JSON.parse(readFileSync(join(consumer, 'Package.resolved'), 'utf8'));
    } else {
      const podfile = join(consumer, 'Podfile');
      writeFileSync(podfile, readFileSync(podfile, 'utf8').replace('tm1470-cocoapods-group', repoKey));
      // netrc's NETRC directory and curl's config keep authentication out of the user's HOME.
      writeFileSync(join(config, '.curlrc'), `netrc-file = "${netrc}"\n`, { mode: 0o600 });
      const env = { ...process.env, NETRC: config, CURL_HOME: config, CP_HOME_DIR: join(run, 'pod-home'), CP_CACHE_DIR: join(run, 'pod-cache'), COCOAPODS_DISABLE_STATS: 'true', DEVELOPER_DIR: '/Applications/Xcode-16.2.app/Contents/Developer', LANG: 'en_US.UTF-8', LC_ALL: 'en_US.UTF-8' };
      command('pod', ['--version'], { env });
      command('pod', ['install'], { cwd: consumer, env });
      command('xcodebuild', ['-project', 'Pods/Pods.xcodeproj', '-target', 'ToneMatePitch', '-configuration', 'Debug', '-sdk', 'iphonesimulator', 'CODE_SIGNING_ALLOWED=NO', 'build'], { cwd: consumer, env });
      summary.lockfile = readFileSync(join(consumer, 'Podfile.lock'), 'utf8');
    }
  }
  summary.result = 'PASS';
} catch (error) {
  summary.result = 'FAIL';
  summary.error = redact(error.message);
  console.error(summary.error);
  process.exitCode = 1;
} finally {
  summary.finishedAt = new Date().toISOString();
  save(join(run, 'summary.json'), summary);
  console.log(`Connection evidence: ${join(run, 'summary.json')}`);
}

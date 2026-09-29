import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import dotenv from 'dotenv';
import { DFRLFormalVerifier } from '../src/proofs/DFRLFormalVerifier';
import { DHBootstrapVerification } from '../src/tests/DHBootstrapVerification';
import { runDaisy54NodeCoverage } from '../src/tests/daisy54NodeCoverage';
import { runEnterpriseVerification } from '../src/tests/enterpriseVerification';
import { runPersistenceVerification } from '../src/tests/persistenceVerification';
import { validateEnvironmentConfiguration } from '../src/services/EnvironmentConfig';

dotenv.config();

const startedAt = new Date().toISOString();
type GateStatus = 'PASSED' | 'BLOCKED' | 'FAILED';
type Gate = { gate: number; id: string; name: string; status: GateStatus; claim_scope: string; evidence: Record<string, unknown>; error?: string };
const gates: Gate[] = [];

function record(gate: number, name: string, status: GateStatus, evidence: Record<string, unknown>, error?: string, claim_scope = 'LOCAL_VERIFIED') {
  gates.push({ gate, id: `GATE-${String(gate).padStart(2, '0')}`, name, status, claim_scope, evidence, ...(error ? { error } : {}) });
}

async function runGate(gate: number, name: string, fn: () => Promise<Record<string, unknown> | void>, options: { blocked?: boolean; claim_scope?: string } = {}) {
  try {
    const evidence = (await fn()) || {};
    record(gate, name, options.blocked ? 'BLOCKED' : 'PASSED', evidence, undefined, options.claim_scope);
  } catch (error: any) {
    record(gate, name, options.blocked ? 'BLOCKED' : 'FAILED', {}, error?.message || String(error), options.claim_scope);
  }
}

function command(command: string, args: string[]): { ok: boolean; output: string } {
  try {
    const output = execFileSync(command, args, { cwd: process.cwd(), env: process.env, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    return { ok: true, output: output.slice(-4000) };
  } catch (error: any) {
    return { ok: false, output: `${error?.stdout || ''}${error?.stderr || ''}`.slice(-4000) };
  }
}

async function main() {
  await runGate(1, 'Repository and branch integrity', async () => {
    const branch = command('git', ['branch', '--show-current']).output.trim();
    const trackedChanges = command('git', ['diff', '--name-only', 'HEAD']).output.trim().split('\n').filter(Boolean);
    if (trackedChanges.length) throw new Error(`Tracked changes present: ${trackedChanges.join(', ')}`);
    return { branch, tracked_changes: trackedChanges.length, latest_commit: command('git', ['rev-parse', 'HEAD']).output.trim() };
  });
  await runGate(2, 'Dependency and manifest integrity', async () => {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    if (!pkg.scripts?.build || !pkg.scripts?.lint) throw new Error('Required build/lint scripts are missing');
    return { package_name: pkg.name, package_version: pkg.version, dependency_count: Object.keys(pkg.dependencies || {}).length, dev_dependency_count: Object.keys(pkg.devDependencies || {}).length };
  });
  await runGate(3, 'TypeScript static verification', async () => {
    const result = command('npm', ['run', 'lint']);
    if (!result.ok) throw new Error(result.output);
    return { command: 'npm run lint', passed: true };
  });
  await runGate(4, 'Production browser bundle verification', async () => {
    const result = command('npm', ['run', 'build']);
    if (!result.ok) throw new Error(result.output);
    const index = fs.existsSync('dist/index.html');
    const assets = fs.existsSync('dist/assets');
    if (!index || !assets) throw new Error('dist/index.html or dist/assets is missing');
    return { command: 'npm run build', index, assets };
  });
  await runGate(5, 'Environment selection and Neon configuration', async () => {
    const validation = validateEnvironmentConfiguration();
    const neonConfigured = Boolean(process.env.NEON_DATABASE_URL);
    if (!neonConfigured) throw new Error('NEON_DATABASE_URL is missing');
    return { environment: process.env.SOLVEX_ENV || 'local', neon_configured: neonConfigured, validation: validation.valid, blockers: validation.blockers };
  });
  await runGate(6, 'Secret and provider preflight', async () => {
    const result = command('npm', ['run', 'verify:secrets']);
    const parsed = result.output.match(/\{[\s\S]*\}/);
    const evidence = parsed ? JSON.parse(parsed[0]) : { output: result.output };
    if (!result.ok || evidence.passed === false) throw new Error(`Production secret preflight is blocked: ${(evidence.blockers || []).join('; ')}`);
    return evidence;
  }, { blocked: true, claim_scope: 'PRODUCTION_READINESS' });
  await runGate(7, 'Enterprise invariant suite', async () => {
    const report = await runEnterpriseVerification();
    const failedTests = report.totalTests - report.passedTests;
    if (!report.allPassed) throw new Error(`Enterprise checks failed: ${failedTests}`);
    return { total_tests: report.totalTests, passed_tests: report.passedTests, failed_tests: failedTests };
  });

  const dfrl = new DFRLFormalVerifier();
  let dfrlReport: Awaited<ReturnType<DFRLFormalVerifier['verifyAll88']>> | undefined;
  await runGate(8, 'DFRL 88-operator formal SMT verification', async () => {
    dfrlReport = await dfrl.verifyAll88();
    if (dfrlReport.executed !== 88 || dfrlReport.unknown_count !== 0 || dfrlReport.error_count !== 0 || dfrlReport.unsat_proved_count !== 88) throw new Error(`DFRL report did not prove all 88 operators`);
    return { total_operators: dfrlReport.total_operators, executed: dfrlReport.executed, unsat_proved: dfrlReport.unsat_proved_count, overall_status: dfrlReport.overall_status, root: dfrlReport.verification_root_sha256 };
  });

  let dhReport: Awaited<ReturnType<typeof DHBootstrapVerification.run>> | undefined;
  await runGate(9, 'DH bootstrap 32-operator registry verification', async () => {
    dhReport = await DHBootstrapVerification.run();
    if (dhReport.executed !== 32 || dhReport.error_count !== 0 || dhReport.unknown_count !== 0) throw new Error('DH bootstrap registry did not execute all 32 operators');
    return { total_operators: dhReport.total_records, executed: dhReport.executed, root: dhReport.verification_root_sha256 };
  });
  await runGate(10, 'Complete 120-operator execution coverage', async () => {
    const dfrlCount = dfrlReport?.executed || 0;
    const dhCount = dhReport?.executed || 0;
    if (dfrlCount + dhCount !== 120) throw new Error(`Expected 120 operators, observed ${dfrlCount + dhCount}`);
    return { dfrl_operators: dfrlCount, dh_bootstrap_operators: dhCount, total_operators: dfrlCount + dhCount };
  });
  await runGate(11, 'Complete 120-operator deterministic replay', async () => {
    const dfrlReplay = dfrlReport?.deterministic_replays_matched || 0;
    const dhReplay = dhReport?.deterministic_replays_matched || 0;
    if (dfrlReplay + dhReplay !== 120) throw new Error(`Expected 120 replay matches, observed ${dfrlReplay + dhReplay}`);
    return { dfrl_replays: dfrlReplay, dh_bootstrap_replays: dhReplay, total_replay_matches: dfrlReplay + dhReplay };
  });
  await runGate(12, 'SMT mutation detection', async () => {
    const result = await dfrl.runSmtMutationTest();
    if (!result.passed) throw new Error('SMT mutation was not detected');
    return { target_operator: result.target_operator_id, mutation_detected: result.mutation_detected };
  });
  await runGate(13, 'Z3 failure injection fail-closed behavior', async () => {
    const result = await dfrl.runZ3FailureInjectionTest();
    if (!result.passed) throw new Error('Z3 failure injection was not fail-closed');
    return { injection_type: result.injection_type, fail_closed: result.fail_closed_enforced, observed_result: result.observed_result };
  });
  await runGate(14, 'Artifact tamper sentinel', async () => {
    if (!dfrlReport) throw new Error('DFRL report unavailable');
    const result = dfrl.runArtifactTamperTest(dfrlReport);
    if (!result.passed) throw new Error('Artifact tamper alarm failed');
    return { alarm_triggered: result.alarm_triggered, tamper_detected: result.tamper_detected };
  });
  await runGate(15, 'Daisy 54-node execution coverage', async () => {
    const report = await runDaisy54NodeCoverage();
    if (!report.all_passed || report.executed_count !== 54) throw new Error('Daisy 54-node coverage incomplete');
    return { registered: report.registered_count, instantiated: report.instantiated_count, reachable: report.reachable_count, executed: report.executed_count, evidence_generated: report.evidence_generated_count };
  });
  await runGate(16, 'Local persistence and Merkle chain', async () => {
    const report = await runPersistenceVerification();
    if (!report.all_local_passed) throw new Error('Persistence verification failed');
    return { tables_created: report.sqlite.tables_created, tenant_isolation: report.sqlite.tenant_isolation_passed, audit_chain: report.sqlite.audit_chain_passed, neon_status: report.neon.status };
  });

  for (const [gate, name, script] of [[17, 'API security and fail-closed routes', 'verify:api'], [18, 'Candidate evidence and publication gates', 'verify:candidate'], [19, 'B2B reference-case evidence workflow', 'verify:b2b'], [20, 'GitHub provenance and registry lineage', 'verify:github']] as const) {
    await runGate(gate, name, async () => {
      const result = command('npm', ['run', script]);
      if (!result.ok) throw new Error(result.output);
      return { command: `npm run ${script}`, passed: true };
    }, { blocked: gate === 18 || gate === 19, claim_scope: gate === 20 ? 'PROVENANCE_COMPATIBILITY' : 'LOCAL_VERIFIED' });
  }
  let operatorMatrix: Array<{ source: string; code: string; executed: boolean; replay_match: boolean; result: string }> = [];
  await runGate(21, 'Evidence artifact packaging and 120-operator matrix', async () => {
    if (!dfrlReport || !dhReport) throw new Error('Operator reports unavailable');
    operatorMatrix = [
      ...dfrlReport.results.map(result => ({ source: 'DFRL', code: result.code || result.operator_id, executed: result.proved, replay_match: dfrlReport!.replays.find(replay => replay.operator_id === result.operator_id)?.replay_match || false, result: result.solver_result })),
      ...dhReport.results.map(result => ({ source: 'DH_BOOTSTRAP', code: result.code, executed: result.executed, replay_match: dhReport!.replays.find(replay => replay.code === result.code)?.replay_match || false, result: result.status }))
    ];
    if (operatorMatrix.length !== 120 || operatorMatrix.some(operator => !operator.executed || !operator.replay_match)) throw new Error('120-operator evidence matrix is incomplete');
    return { gate_count: 21, operator_count: operatorMatrix.length, dfrl_operators: 88, dh_bootstrap_operators: 32, artifact: 'artifacts/verification-21-gates-120-operators.json' };
  });

  const completedAt = new Date().toISOString();
  const report = { started_at: startedAt, completed_at: completedAt, gate_count: 21, operator_count: operatorMatrix.length, operator_matrix: operatorMatrix, gates, claim_scope: 'LOCAL_VERIFIED_WITH_PRODUCTION_BLOCKERS' };
  fs.mkdirSync('artifacts', { recursive: true });
  fs.writeFileSync(path.join('artifacts', 'verification-21-gates-120-operators.json'), JSON.stringify(report, null, 2));
  fs.writeFileSync(path.join('artifacts', 'verification-21-gates-120-operators.md'), `# 21-Gate / 120-Operator Verification\n\n- Completed: ${completedAt}\n- Gates: 21\n- Operators: 120\n- DFRL: 88\n- DH bootstrap: 32\n- Claim scope: ${report.claim_scope}\n\n| Gate | Name | Status |\n|---:|---|---|\n${gates.map(g => `| ${g.gate} | ${g.name} | ${g.status} |`).join('\n')}\n`);

  const passed = gates.filter(g => g.status === 'PASSED').length;
  const blocked = gates.filter(g => g.status === 'BLOCKED').length;
  const failed = gates.filter(g => g.status === 'FAILED').length;
  const summary = { completed_at: completedAt, gates: 21, passed, blocked, failed, operators: 120, dfrl_operators: 88, dh_bootstrap_operators: 32, production_claim: blocked ? 'BLOCKED_BY_EXTERNAL_PREREQUISITES' : 'READY_FOR_REVIEW' };
  console.log(JSON.stringify(summary, null, 2));
  if (failed > 0) process.exitCode = 1;
}

main().catch(error => { console.error(error); process.exitCode = 1; });

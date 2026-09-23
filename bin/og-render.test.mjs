import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const renderer = process.env.OG_RENDER_SCRIPT ?? fileURLToPath(new URL("./og-render.mjs", import.meta.url));

test("serial and parallel rendering produce identical images and propagate failures", async () => {
  const dir = await mkdtemp(join(tmpdir(), "og-render-test-"));
  const manifest = join(dir, "manifest.json");
  const run = (count) => spawnSync(process.execPath, [renderer, manifest], {
    env: { ...process.env, OG_RENDER_JOBS: String(count) },
    encoding: "utf8",
    timeout: 30_000,
  });

  try {
    const jobs = [];
    for (const [i, color] of ["red", "blue", "green"].entries()) {
      const svg = join(dir, `${i}.svg`);
      await writeFile(svg, `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" fill="${color}"/></svg>`);
      jobs.push({ svg, out: join(dir, `${i}.webp`) });
    }
    await writeFile(manifest, JSON.stringify(jobs));
    const serial = run(1);
    assert.equal(serial.status, 0, serial.stderr);
    const expected = await Promise.all(jobs.map(({ out }) => readFile(out)));
    for (const { out } of jobs) await rm(out);

    const parallel = run(2);
    assert.equal(parallel.status, 0, parallel.stderr);
    const actual = await Promise.all(jobs.map(({ out }) => readFile(out)));
    assert.deepEqual(actual, expected);
    assert.ok(actual.every((data) => data.length > 0));
    assert.notDeepEqual(actual[0], actual[1]);

    const invalid = run(0);
    assert.equal(invalid.status, 1, invalid.stderr);
    assert.match(invalid.stderr, /OG_RENDER_JOBS must be a positive integer/);

    await rm(jobs[1].svg);
    const failed = run(2);
    assert.equal(failed.status, 1, failed.stderr);
    assert.match(failed.stderr, /ENOENT/);

    await writeFile(manifest, "[]");
    const empty = run(2);
    assert.equal(empty.status, 0, empty.stderr);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

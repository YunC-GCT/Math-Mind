// fixtures/fail/any-type.ets — sample that MUST trigger arkts-no-any-unknown
// (used to verify lint actually catches violations)

function bad1(x: any): any {
  return x;
}

function bad2(unknown: unknown) {
  console.info(unknown);
}

const a: any = 42;  // also bad
let u: unknown;

interface Mixed {
  ok: string;
  bad: any;  // also bad
}
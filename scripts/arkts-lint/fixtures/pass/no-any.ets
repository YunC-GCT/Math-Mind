// fixtures/pass/no-any.ets — sample that should NOT trigger any violation
// (used to verify lint produces no false positives)

interface Foo {
  name: string;
  count: number;
}

function greet(f: Foo): string {
  return 'hello ' + f.name;
}

class Container {
  items: string[] = [];
  add(item: string): void {
    this.items.push(item);
  }
}

const x: number = 42;
const arr: Array<number> = [1, 2, 3];
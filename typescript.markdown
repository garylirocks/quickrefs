TypeScript
=============

- [Basic Types](#basic-types)
- [Type assertions](#type-assertions)
- [Interfaces](#interfaces)
  - [Excess property checking](#excess-property-checking)
  - [Extending](#extending)
  - [Function Types](#function-types)
  - [Hybrid Types](#hybrid-types)
- [Functions](#functions)
  - [Overload](#overload)
- [Classes](#classes)
- [Generics](#generics)
  - [Generic Interface](#generic-interface)
  - [Generic Constraints](#generic-constraints)


## Basic Types

* `boolean`
* `number`
* `string`
* Arrays: `Array<elemType>` or `elemType[]`
* Tuple: fixed number of elements with known types:
    ```ts
    let x: [string, number];
    x = ['hello', 10];

    console.log(x[1].substr(1));    // Error, no 'substr' for 'number'
    x[3] = 'world';                 // OK, elements outside of the known indices got a union type 'string | number'
    ```
* Enum
    ```ts
    // this will create a Fruit object, with bi-direction key-value mappings between numbers and the string values, 'Strawberry' will be mapped to 2
    enum Fruit { Apple = 10, Pear = 1, Strawberry };

    const myFruit = Fruit.Pear;     // access using string key
    console.log(Fruit[2]);          // access using number key
    ```
* Any
    ```ts
    let notSure: any = 4;
    notSure.notExistMethod();       // OK

    let mysticArray: any[] = [1, true, 'ghost'];
    ```
* `void`: mostly used for functions that do not return a value;
* `null` and `undefined`
    * By default, they are subtypes of all other types, you can assign `null` and `undefined` to something like `number`;
    * When `--strictNullCheck` flag is turned on, `null` and `undefined` are only assignable to `void` and their respective types;
* Never: return type for a function that always throws an exception or one never returns:
    ```ts
    // Function returning never must have unreachable end point
    function error(message: string): never {
        throw new Error(message);
    }

    // Inferred return type is never
    function fail() {
        return error("Something failed");
    }

    // Function returning never must have unreachable end point
    function infiniteLoop(): never {
        while (true) {
        }
    }
    ```
* `object`: non-primitive type, anything that is not `number`, `string`, `boolean`, `symbol`, `null` or `undefined`;


## Type assertions

* Tell the compiler what the type should be;
* No runtime impact, used purely by the compiler;
    ```ts
    let someValue: any = "this is a string";

    let strLength: number = (someValue as string).length;
    ```


## Interfaces

```ts
// define an interface
interface Person {
    firstName: string;
    readonly lastName: string;      // specify it to be readonly
}

// use type annotation here
function greeter(person: Person) {
    return "Hello, " + person.firstName + " " + person.lastName;
}

// only the shape matters, you can pass in arguments with addtional prop 'middleName'
const user = { firstName: "Jane", lastName: "User", middleName: "G" };
greeter(user);
```

### Excess property checking

```ts
interface Cat {
    name: string,
    color?: string,
};

// this is fine
const aCat = { name: 'Gary', colour: 'white' };
const myCat1: Cat = aCat;

// Error! TypeScript do excess property checking when assigning object leterals which has excess properties
const myCat2: Cat = { name: 'Gary', colour: 'white' };
```

Can be fixed using a type assertion:

```ts
const myCat2: Cat = { name: 'Gary', colour: 'white' } as Cat;
```

A better way is adding a string index signature:

```ts
interface Cat {
    name: string,
    color?: string,
    [prop: string]: any,        // a index signature
};
```

### Extending

```ts
// define an interface
interface Person {
    firstName: string;
    lastName: string;
}

interface Employee extends Person {
    role: string;
}

const a: Employee = {
    firstName: 'Gary',
    lastName: 'Li',
    role: 'Dev',
};
```

### Function Types

Interfaces can not only describe normal object, it can also be used to describe a function object:
* Each param in the param list requires both name and type;
* The names of params do not need to match;

```ts
interface Func {
    (a: number, b: number): number;
}

const foo: Func = function (x: number, y: number) {
    return x + y;
}
```

### Hybrid Types

```ts
// a function object, but has other custom properties
interface Func {
    (a: number, b: number): number;
    bar: string;
}

let foo: Func;
foo = (function (x: number, y: number) {
    return x + y;
} as Func);

foo.bar = 'xxx';
```


## Functions

### Overload

```ts
// two overloads
function add(x: number, y: number): number;
function add(x: string, y: string): string;

// this is not part of the overload list, it only becomes the signature if overloads list above don't exist
function add(x: any, y: any): any {
    if (typeof x === 'number') {
        return x + y;
    } else if (typeof x === 'string') {
        return x + ' ' + y;
    }
}

add(1, 2);
add('hello', 'world');

add(2, 'world');    // Error!
```


## Classes

* classes in TypeScript are just a shorthand for the same prototype-based OO used in JS;
* class members can be `public`, `private` or `protected`;
* You can declare members in the constructor param list;
    ```ts
    classs Student {
        fullName: string;

        // public arguments for the constructor is a shorthand that allows automatical creation of properties
        constructor(public firstName: string, public middleInitial: string, public lastName: string) {
            this.fullName = firstName + " " + middleInitial + " " + lastName;
        }
    }

    interface Person {
        firstName: string;
        lastName: string;
    }

    function greeter(person: Person) {
        return "Hello, " + person.firstName + " " + person.lastName;
    }

    let user = new Student("Jane", "M.", "User");

    document.body.innerHTML = greeter(user);
    ```
* TypeScript is a structural system: types are compatible if the types of all members are compatible: this doesn't apply to `private` and `protected` members, they must be originated from the same declaration to be compatible: this means subclass are compatible with baseclass, but another class with exact member structure is not;
    ```ts
    class Animal {
        private name: string;
        constructor(theName: string) { this.name = theName; }
    }

    class Rhino extends Animal {
        constructor() { super("Rhino"); }
    }

    class Employee {
        private name: string;
        constructor(theName: string) { this.name = theName; }
    }

    let animal = new Animal("Goat");
    let rhino = new Rhino();
    let employee = new Employee("Bob");

    animal = rhino;
    animal = employee;      // Error: 'Animal' and 'Employee' are not compatible
    ```
* When you declare a class, you are actually creating two types at the same time:
    ```ts
    class Man {
        static gender = "Male";

        constructor(public name: string) {
        }

        info() {
            console.log('name: ' + this.name);
            console.log('gender: ' + Man.gender);
        }
    }

    // 'Man' is the class name, also the type of all instances
    const gary: Man = new Man('Gary');
    console.log(gary.info());

    // 'Man' class itself is actually a constructor function
    // its type is 'typeof Man', it has a 'gender' property
    const alienMan: typeof Man = Man;
    alienMan.gender = "Alien";

    const gary2: Man = new alienMan('Gary');
    console.log(gary2.info());
    ```


## Generics

Define a function with type variable:

```ts
function identity<T>(arg: T): T {
    return arg;
}
```

When using this function, you can either

* set the type explicitly:

    ```ts
    let output = identity<string>("myString");
    ```

* or let the compiler figure out the type argument to by `string` based on the argument passed in

    ```ts
    let output2 = identity("myString");
    ```

### Generic Interface

The above example can be transformed to:

```ts
interface GenericIdentityFn<T> {
    (arg: T): T;
}

function identity<T>(arg: T): T {
    return arg;
}

let myIdentity: GenericIdentityFn<number> = identity;
```

### Generic Constraints

* Extending an interface:

    ```ts
    interface Lengthwise {
        length: number;
    }

    function loggingIdentity<T extends Lengthwise>(arg: T): T {
        console.log(arg.length);  // Now we know it has a .length property, so no more error
        return arg;
    }
    ```

* Constrained by another type parameter:

    ```ts
    function getProperty<T, K extends keyof T>(obj: T, key: K) {
        return obj[key];
    }

    let x = { a: 1, b: 2, c: 3, d: 4 };

    getProperty(x, "a"); // okay
    getProperty(x, "m"); // error: Argument of type 'm' isn't assignable to 'a' | 'b' | 'c' | 'd'.
    ```

* Class types in generics:

    ```ts
    class BeeKeeper {
        hasMask: boolean;
    }

    class ZooKeeper {
        nametag: string;
    }

    class Animal {
        numLegs: number;
    }

    class Bee extends Animal {
        keeper: BeeKeeper;
    }

    class Lion extends Animal {
        keeper: ZooKeeper;
    }

    function createInstance<A extends Animal>(c: new () => A): A {
        return new c();
    }

    createInstance(Lion).keeper.nametag;  // typechecks!
    createInstance(Bee).keeper.hasMask;   // typechecks!
    ```

    for any `class A`, you can type it as `new () => A`, meaning it can be `new`ed to create a `A` instance

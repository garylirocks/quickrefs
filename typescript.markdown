TypeScript
=============

## Interfaces and Type annotations

    # define an interface
    interface Person {
        firstName: string;
        lastName: string;
    }

    # use type annotation here
    function greeter(person: Person) {
        return "Hello, " + person.firstName + " " + person.lastName;
    }

    let user = { firstName: "Jane", lastName: "User" };

    document.body.innerHTML = greeter(user);


## Classes

classes in TypeScript are just a shorthand for the same prototype-based OO used in JS

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


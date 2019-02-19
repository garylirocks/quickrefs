# Design Patterns

- [Dependency Injection](#dependency-injection)
- [Inversion of Control](#inversion-of-control)
- [Delegation](#delegation)

## Dependency Injection

[Wiki Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection)

**A fundamental requirement of the pattern**: passing a service to a client, rather than allowing the client to build or find the service.

Dependency injection involves four roles:

- the **service** object(s) to be used
- the **client** object that is depending on the services
- the **interfaces** that define how the client may use the services
- the **injector**, which is responsible for constructing the services and injecting them into the client

The **injector** may be referred to by other names: assembler, provider, container, factory, builder, spring, construction code, or main

- Inversion of Control (IoC) is more general than Dependency Injection;
- Some attempts at Inversion of Control do not provide full removal of dependency but instead simply substitute one form of dependency for another. As a rule of thumb, if a programmer can look at nothing but the client code and tell what framework is being used, then the client has a hard-coded dependency on the framework.

Simple Example:

- Without dependency injection

```java
// An example without dependency injection
public class Client {
    // Internal reference to the service used by this client
    private Service service;
    // Constructor
    Client() {
        // Specify a specific implementation in the constructor instead of using dependency injection
        this.service = new ServiceExample();
    }
    // Method within this client that uses the services
    public String greet() {
        return "Hello " + service.getName();
    }
}
```

- With dependency injection

```java
public class Injector {
    public static void main(String[] args) {
        // Build the dependencies first
        Service service = new ServiceExample();
        // Inject the service, constructor style
        Client client = new Client(service);
        // Use the objects
        System.out.println(client.greet());
    }
}
```

## Inversion of Control

- Traditional program: your custom code calls functionality from a library;
- **Inversion of control**: a framework takes care of the flow of control, and calls your custom code;

It is sometimes referred to as "_Hollywood Principle: Don't call us, we'll call you_"

Desc: **find the code to execute by reading its description from external configuration instead of with a direct reference in the code itself**

## Delegation

A delegator delegates something to do by another object

```java
class RealPrinter {    // the "delegate"
    void print() {
        System.out.println("something");
    }
}

class Printer {    // the "delegator"
    RealPrinter p = new RealPrinter();  // create the delegate
    void print() {
        p.print(); // calls the delegate
    }

    // to the outside world it looks like Printer actually prints.
    public static void main(String[] arguments) {
        Printer printer = new Printer();
        printer.print();
    }
}
```

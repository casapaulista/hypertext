# Hypertext
Hypertext is a static site generator (SSG) inspired by [Avantguarda's Hipertexto](https://github.com/avantguarda/hipertexto).

## (Expected) Usage
Hypertext is currently under-development and most of desired features are not working as of now. Anyway, check our desired behavior.

### `init`
As stated in the `-h` command, `init` creates a new Hypertext project. It is important to notice that it does require an empty folder in order to work.

**Requirements**
- An empty folder
- A name for the project

**Example**
Create a new folder for the project:
```sh
mkdir website
```

Init the Hypertext project:
```sh
hx init website
```

### `build`
The command `build` generates the website in the output directory, defaults to `/public`.

```sh
hx build
```

### `serve`
This command performs two actions, `serve` build the website and then serves it with a tiny webserver.

```sh
hx serve
```

### `help`
This command does not require any introductions, it is a default command with all necessary additional explanation about the application. Although, 
it is worth noticing that it also works for each of the mentioned commands, providing a broader usage guide to each of Hypertext's commands.

To prompt all information available about the `init` command, you can enter:
```sh
hx init --help
```

## License
This project is licensed under GNU GPLv3 License. Check [LICENSE](LICENSE) for more information.

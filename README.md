# Hypertext
*The future is static.*

Static website generation, refined. Transform markdown into lightning-fast websites with elegant simplicity.

## Installation
```sh
brew install hypertext
```

## Usage
```sh
hx init   # Create a new project
hx build  # Generate the website
hx serve  # Preview locally
```

## Philosophy
Remove the unnecessary. What remains is pure intention.

## Structure
```sh
content/   # Your words
static/    # Your assets
styles/    # Your aesthetic
templates/ # Your structure
public/    # Your website
```

## Templates — Powered by Blueprint
```html
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    {{ content }}
</body>
</html>
```

## Content — Powered by Syntax
```md
--- 
template: page.html
title: A great article
---

# Heading

Content
```

## License
This project is licensed under GNU GPLv3 License. Check [LICENSE](LICENSE) for more information.

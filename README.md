<p align="right"><a href="README.pt_BR.md">Português</a></p>

<h1 align="center">
   <img src="imgs/logo.svg" width=256 alt="GIMP">
   <br />
   Lua WPP | <a href="https://github.com/natanael-b/lua4webapps/archive/refs/heads/framework.zip">Download</a>
</h1>

<p align="center"><i>"A lightweight Lua-based HTML framework designed for creating static web applications"</i></p>

<p align="center">
   <a href="https://github.com/natanael-b/lua4webapps/fork">
     <img height=26 alt="Create a fork on github" src="https://img.shields.io/badge/Fork--Me-H?style=social&logo=github">
   </a>
   <img height=26 alt="GitHub Repo stars" src="https://img.shields.io/github/stars/natanael-b/lua4webapps?style=social">
   <img height=26 alt="Dependency free" src="https://img.shields.io/badge/Zero-Dependency-blue">
  
</p>

This framework allows you to define HTML elements using Lua's native syntax, giving you the ability to build structured HTML documents programmatically. The framework supports extendable elements, self-closing tags, and allows for nested children with customizable properties.

# Features

- **Declarative HTML Elements:** Easily create and manipulate HTML code using Lua's syntax.
- **Self-closing Tags:** Automatically handles self-closing HTML tags like <br />, <img />, and more.
- **Components:** Extend and customize existing HTML elements with additional properties and children.
- **Dynamic Tag Handling:** Unrecognized tags are automatically interpreted as new HTML elements.
- **HTML Encoding:** Automatically encodes characters for safe HTML rendering.
- **Custom Syntax for Tables and Forms:** Supports custom handling of common elements like `<table>`, `<select>`, and `<form>`.

# Getting Started

### Installation

To use this framework, simply include the Lua script in your project.

<details>
<summary>Using git</summary>

```bash
# Clone the repository
git clone https://github.com/your-username/lua-web-framework.git
```

</details>

<details>
<summary>Using zip</summary>

- Click [download](https://github.com/natanael-b/lua-wpp/archive/refs/heads/framework.zip)
- Extract the contents of the zip to some folder

</details>

### How to use?

1. Create a file for example `Project.lua` containing:

```lua
Pages = {
   sources = "lua", -- Location of Lua pages
   output="www",    -- Where pages will be rendered

   -- List of pages separated by ,
   'index',
}

-- Keep bellow lines untouched
local f = io.open("lua4webapps-framework/init.lua")
local _ = f and {require "lua4webapps-framework",f:close()} or require "lua4webapps"
```

2. Now create a folder called "lua" and in it an `index.lua` file with the content:

```lua
-- Create a simple HTML document
html {
    head {
      title "Example"
    },
    body {
        h1 "Hello, Lua Framework!",
        p "This is a paragraph generated using Lua.",
        img {src = "image.jpg", alt = "Sample Image"},
        ul {
            "First Item",
            "Second Item",
            "Third Item"
        }
    }
}
```

3. Run `lua5.4 Project.lua` you will have a page built on `www` with the name containing:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <style>body {font-family: sans-serif;}</style>
    <title>Example</title>
</head>
<body>
    <h1>Hello, Lua Framework!</h1>
    <p>This is a paragraph generated using Lua.</p>
    <img src="image.jpg" alt="Sample Image" />
    <ul>
        <li>First Item</li>
        <li>Second Item</li>
        <li>Third Item</li>
    </ul>
</body>
</html>

```

# Extending Tags

```lua
local customDiv = div:extends {
    class = "custom-div",
    childrens = {
        span "This is inside a custom div"
    }
}

html {
    body {
        customDiv "Custom content"
    }
}
```

Will render:

```html
<html>
    <head></head>
    <body>
        <div class="custom-div">
        <span>This is inside a custom div</span>
        Custom content
    </div>
    </body>
</html>
```

# Pro tips:

- You can simplify use of `ul`, `ol` and `select`:

```lua
ul {
  "Item A",
  "Item B",
  "Item C",
}

ol {
  "Item A",
  "Item B",
  "Item C",
}

select {
  "Item A",
  "Item B",
  "Item C",
}
```

Rendered:

```html
<ul> {
  <li>Item A</li>
  <li>Item B</li>
  <li>Item C</li>
</ul>

<ol> {
  <li>Item A</li>
  <li>Item B</li>
  <li>Item C</li>
</ol>

<select> {
  <option value="Item A">Item A</option>
  <option value="Item B">Item B</option>
  <option value="Item C">Item C</option>
</select>
```

- `select` has a second way:

```lua
select {
  {"Item A","X"},
  {"Item B","Y"},
  {"Item C","Z"},
}
```

Rendered:

```html
<select> {
  <option value="X">Item A</option>
  <option value="Y">Item B</option>
  <option value="Z">Item C</option>
</select>
```

- You can use Lua syntax to declare `table` elements:

```lua
table {
   {'A1', 'B1', 'C1'},
   {'A2', 'B2', 'C2'},
   {'A3', 'B3', 'C3'},
}
```

Rendered:

```html

<table>
    <tr>
        <td>A1</td>
        <td>B1</td>
        <td>C1</td>
    </tr>
    <tr>
        <td>A2</td>
        <td>B2</td>
        <td>C2</td>
    </tr>
    <tr>
        <td>A3</td>
        <td>B3</td>
        <td>C3</td>
    </tr>
</table>
```

# License
This project is licensed under the MIT License.

# Contributing
Feel free to submit issues or contribute to the project by creating pull requests.

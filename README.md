## Profile

A simple shell tool to assist with creating and loading `.env` files

### Installation

Clone this repository somewhere and then edit your `~/.bashrc` or `~/.zshrc`

```
source <checkout_dir>/profile.sh
```

### Usage

#### Creating Environments

Create or edit an `.env` file in the current working directory

```
profile init
```

Create or edit an .env file in the current working directory, and create a symlink to it in `~/.environments`.

By creating a symlink you can then refer to that environment from anywhere on the filesystem.

```
profile init example
```

#### Sourcing Environments

Source an environment file. Starting with the current working directory and continuing up the parent directory tree until it finds a `.env` file

```
profile source
```

Source a linked environment file

```
profile source example
```

Source a linked environment file and change directory to its parent directory

```
profile switch example
```

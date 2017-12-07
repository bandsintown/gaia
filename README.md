[![Build status](https://badge.buildkite.com/c701c3b9833a32d772707ca89c5ac4503a414523ee1ea6a573.svg)](https://buildkite.com/bandsintown/gaia)

What is Gaia ?
====

In Greek mythology, Gaia is the personification of the Earth and one of the Greek primordial deities. Gaia is the ancestral mother of all life: the primal Mother Earth goddess.

More seriously, Gaia is just a wrapper script for [Terraform](https://www.terraform.io/). Terraform is a fantastic tool to bring infrastructure as code, but running Terraform in automation 
is sometimes tedious. That's why we develop this very lean bash script just to wrap Terraform calls and to bring not built-in features.

## Motivation

At Bandsintown, we are using Terraform to create our infrastructure and to deploy our services.

When we started to use Terraform, it did not support environments and that's precisely why we implemented the `gaia` script to manage the environments and the remote state for each environment.

Then Gaia evolved to add some other features:

- Hooks
- Terraform in Docker
- Terraform Docs
- TFLint
...


## Installation

To easily install Gaia on OS X, you can just use Homebrew doing:

```sh
brew tap bandsintown/tap
brew install gaia
```

for the other platforms you can simply clone the directory and add the `bin` directory in your `PATH`.


## Usage

### Project Structure

Gaia is expecting to organize projects following this structure:


```bash
.
├── env
│   ├── dev.tfvars
│   └── prod.tfvars
└── module1
    ├── env
    │   ├── dev.tfvars
    │   └── default.tfvars
    └── main.tf
└── module2
    ├── env
    │   ├── prod.tfvars
    │   └── default.tfvars
    └── main.tf
```

At Bandsintown we've found this project format to be very successful and use it in all of our Terraform repositories.


### Environments

Gaia offers a flexible way to define configuration for an environment.

The configuration can be set at different levels: 
 
1. **Command Line**:  Configuration might be passed through command line setting the Terraform variables with `-var`. 
The *command line* configuration has the higher precedence.

2. **Environment variable**: The environment variable `TERRAFORM_VARS` might be set to define configuration (e.g `TERRAFORM_VARS="-var service=search-api"`)

3. **Module Configuration**: The configuration might be defined or overrode at the module level specifying a `.tfvars` file based on the name of the environment. (e.g `dev.tfvars` for `dev` environment). The configuration for the module should be defined here. 

4. **Global Configuration**: The configuration might be defined specifying a `.tfvars` file based on the name of the environment. (e.g `dev.tfvars` for `dev` environment). The global configuration should be defined here.
The *global configuration* has the lower precedence.


### Gaia configuration

Gaia itself can be configure to initialize the environment (hooks, runtime...). 

Each module can contains a `.gaia` file defining configuration for this module. 
A `.gaia` file is just a `bash` script defining logic to initialize Gaia to perform actions.

### Hooks

Hooks are a convenient way to run commands before or after the main command. 

Gaia implements hooks just defining `bash` function in `.gaia` files.

For example:

```bash
#!/bin/bash

pre_plan() {
  echo "This hooks run before the plan command" 
}

post_apply() {
  echo "This hooks run after the apply command" 
}

```

### Terraform in Docker

At Bandsintown, we have multiple Terraform repositories and each developers can run Terraform from his laptop. 
In this context, managing Terraform version is crucial to be sure we have consistent run and to prevent state conflicts. 

That's why we implemented in Gaia the ability to run Terraform in Docker. 

The version of Terraform can be set in a `.gaia` file at root or module level just exporting the following environment variables:

 - `TERRAFORM_IN_DOCKER`: Define if Terraform runs in Docker
 - `TERRAFORM_VERSION`: The Terraform version (default: `latest`)

Gaia is using the [official Terraform Docker image](https://store.docker.com/community/images/hashicorp/terraform) by default, but it's possible to define a custom Docker image setting:
 
 - `TERRAFORM_DOCKER_IMAGE`: The Docker image used to run Terraform. (default: `hashicorp/terraform`)

### Terraform Docs

The Segment.io team released a tool named [`terraform-docs`](https://github.com/segmentio/terraform-docs) to generate documentation for the Terraform modules.

We integrated in Gaia the ability to run `terraform-docs` in order to keep our Terraform module documentation up to date.

Note: Terraform Docs has to be installed (does not run yet in Docker)

### TFlint

[TFLint](https://github.com/wata727/tflint) is another tool for detecting errors that can not be detected by `terraform plan`.

We integrated in Gaia TFLint in order to detect errors in our CI.

In order to run TFLint in Docker, you have to defined the following variables:

 - `TFLINT_IN_DOCKER`: Define if TFLint runs in Docker
 - `TFLINT_VERSION`: The TFLint version (default: `latest`)

Gaia is using the [official TFLint Docker image](https://hub.docker.com/r/wata727/tflint) by default, but it's possible to define a custom Docker image setting:
 
 - `TFLINT_DOCKER_IMAGE`: The Docker image used to run TFLint. (default: `wata727/tflint`)


## License

All the code contained in this repository, unless explicitly stated, is
licensed under ISC license.

A copy of the license can be found inside the [LICENSE](LICENSE) file.

## Resources

Those resources about Terraform defined some best practices we try to follow 

 - [Comprehensive Guide to Terraform](https://blog.gruntwork.io/a-comprehensive-guide-to-terraform-b3d32832baca)
 - [Terraform testing strategies](https://www.contino.io/insights/top-3-terraform-testing-strategies-for-ultra-reliable-infrastructure-as-code)


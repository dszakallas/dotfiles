---
name: manage-devenv-processes
description: Use this skill when the user asks to run, stop, check the status of, or view logs for local development environment processes defined in devenv.nix projects. This skill provides instructions on how to use the 'devenv processes' command suite for process management.
---
# Devenv process management

Devenv provides built-in process management with supervision, socket activation, file watching, and dependency management.

## Overview

The development environment and services are declaratively defined in `devenv.nix`. 

### Process management

Process management is handled via the `devenv processes` command suite.

#### 1. Starting Processes

* **Start all processes in the background:**
  ```bash
  devenv processes start
  ```
  *(Alternatively, you can run `devenv up -d` to start the process manager in detached mode).*

* **Start a specific process:**
  ```bash
  devenv processes start <process-name>
  ```
  Example:
  ```bash
  devenv processes start service
  ```

#### 2. Checking Status

* **List all processes and their current status/phase:**
  ```bash
  devenv processes list
  ```

* **Check details of a specific process:**
  ```bash
  devenv processes status <process-name>
  ```
  Example:
  ```bash
  devenv processes status service
  ```

#### 3. Viewing Logs

* **Show stdout/stderr output for a process:**
  ```bash
  devenv processes logs <process-name>
  ```
  Example:
  ```bash
  devenv processes logs service
  ```

#### 4. Stopping Processes

* **Stop a specific process:**
  ```bash
  devenv processes stop <process-name>
  ```
  Example:
  ```bash
  devenv processes stop service
  ```

* **Stop the process manager and shut down all processes:**
  ```bash
  devenv processes down
  ```

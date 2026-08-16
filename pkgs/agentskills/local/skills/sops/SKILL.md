---
name: sops
description: "Work with SOPS-encrypted secret files (.sec.<ext>), check encryption status, encrypt/decrypt secrets, and manage secret files safely using SOPS (Secrets OPerationS) with age, SSH keys, or PGP. Make sure to use this skill whenever inspecting, editing, encrypting, decrypting, rotating, or adding/removing recipients from SOPS-managed secret files or working with .sops.yaml."
tags: [sops, secrets, age, ssh, encryption, security]
---

# SOPS Secret Management

Use this skill when managing or creating secret files (`.sec.<ext>`) in repositories using SOPS (Secrets OPeration System) for secret encryption.

## Key Principles & Safety Rules

- **Secret File Naming**: Encrypted secret files are typically associated with the `.sec.<ext>` extension (e.g. `secret.sec.yaml`, `credentials.sec.json`).
- **SOPS Configuration**: SOPS configuration rules are defined in `.sops.yaml` in the repository root.
- **NEVER inspect or edit decrypted secrets directly**: Do not attempt to read or edit decrypted secrets without explicit user instructions. Prompt the user if modification or creation of a secret is required.
- **Creating New Secrets**: When creating a new secret, place unencrypted secret files with placeholder values and ask the user to fill and encrypt them.
- **Pre-commit Verification**: Pre-commit checks ensure that every committed secret is encrypted. Never turn off commit verification (`git commit --no-verify`) when making changes.

## Key Backends & Resolution Order

sops supports multiple key providers (`age`, SSH keys as age recipients, PGP, AWS KMS, GCP KMS). `age` and SSH keys are the primary backends used for local and repository workflows.

### Key Lookup Order

sops searches for private keys in the following order:

1. `SOPS_AGE_SSH_PRIVATE_KEY_FILE` — Explicit path to an SSH private key file
2. `SOPS_AGE_SSH_PRIVATE_KEY_CMD` — Command whose stdout yields the SSH private key
3. `SOPS_AGE_KEY` — Raw inline `age` secret key material
4. `SOPS_AGE_KEY_FILE` — Path to `age` key file (e.g. `~/.age/key.txt`)
5. `SOPS_AGE_KEY_CMD` — Command whose stdout yields the `age` key
6. `~/.config/sops/age/keys.txt` — Default `age` key location
7. `~/.ssh/id_ed25519` — SSH auto-discovery (`ed25519`)
8. `~/.ssh/id_rsa` — SSH auto-discovery fallback (`RSA`)

Set `SOPS_DISABLE_VERSION_CHECK=1` in your environment to suppress version check warnings.

### age Backend

Generate and manage age keys:

```bash
# Generate a new age key pair
age-keygen -o key.txt

# Extract the public key for .sops.yaml
age-keygen -y key.txt # or: cat key.txt | grep 'public key'

# Decrypt using a specific age key file
SOPS_AGE_KEY_FILE=key.txt sops --decrypt secrets.sec.yaml
```

### SSH Keys as age Recipients (sops v3.9.1+, recommended v3.13.1+)

sops supports using SSH public keys (`ssh-ed25519`, `ssh-rsa`) directly as `age` recipients.

> [!IMPORTANT]
> Only `ssh-ed25519` and `ssh-rsa` key types are supported. `ecdsa` key types are not supported.

> [!WARNING]
> **sops-nix compatibility**: `sops-nix` currently does **not** work with SSH public keys directly specified as `age` recipients in `.sops.yaml`. Although `sops-nix` auto-imports host SSH keys (like `/etc/ssh/ssh_host_ed25519_key`) by converting them to native `age` keys on boot, files encrypted directly for an `ssh-ed25519` recipient string will fail to decrypt under `sops-nix`. When preparing secrets for `sops-nix`, convert the SSH public key to a plain `age` key using `ssh-to-age`:
> ```bash
> ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
> # Output: age1...
> ```
> Use the resulting `age1...` recipient in `.sops.yaml` instead of the raw `ssh-ed25519 ...` public key string.

#### Encrypting with SSH Public Keys

```bash
# Pass the SSH public key string directly
sops --encrypt --age "ssh-ed25519 AAAA... user@host" --in-place secrets.sec.yaml

# Comma-separated multiple recipients (SSH key + age key)
sops --encrypt --age "ssh-ed25519 AAAA...,age1xxx..." --in-place secrets.sec.yaml
```

#### Decrypting with SSH Private Keys

Auto-discovery automatically checks `~/.ssh/id_ed25519` and `~/.ssh/id_rsa`. Or specify a custom key file:

```bash
SOPS_AGE_SSH_PRIVATE_KEY_FILE=/path/to/id_ed25519 sops --decrypt secrets.sec.yaml
```

*Note on passphrase-protected SSH keys*: Automated non-interactive runs will fail if the key requires a passphrase unless it is loaded into `ssh-agent`.

## Common Operations

### Check Encryption Status

Check if a secret file is encrypted:

```bash
sops filestatus <secret-file> # Output: {"encrypted":true} or {"encrypted":false}
```

### Encrypt a Secret File

Encrypt a file in-place:

```bash
sops encrypt --in-place <secret-file>
```

### Decrypt to Standard Output

Read decrypted contents to stdout without writing plaintext to disk:

```bash
sops --decrypt <secret-file>
```

### Extract a Single Value

Extract a specific key path from an encrypted file:

```bash
sops --decrypt --extract '["database"]["password"]' secrets.sec.yaml
```

### Interactive Editing (User)

Users can edit encrypted secret files interactively (decrypts, launches `$EDITOR`, re-encrypts on save):

```bash
sops edit <secret-file>
```

### Rotate Data Keys & Recipients

```bash
# Rotate the internal data encryption key
sops --rotate --in-place <secret-file>

# Add a new age recipient and rotate
sops --rotate --add-age age1newrecipient... --in-place <secret-file>

# Remove an age recipient and rotate
sops --rotate --rm-age age1oldrecipient... --in-place <secret-file>
```

### Update Keys from `.sops.yaml`

Re-encrypt files to match updated `.sops.yaml` recipient rules:

```bash
# Interactive mode (prompts for confirmation)
sops updatekeys <secret-file>

# Non-interactive mode (for scripts / automated tasks)
sops updatekeys --yes <secret-file>
```

### Manual Pre-commit Check

Run the `sops-encrypt` pre-commit check manually:

```bash
prek run :sops-encrypt --files <secret-file>
```

## `.sops.yaml` Configuration Reference

Place `.sops.yaml` at the repository root to define automatic recipient rules based on file paths:

```yaml
creation_rules:
  - path_regex: .*\.sec\.yaml$
    age: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@host,age1ql3z7..."
  - path_regex: secrets/.*\.env$
    age: "age1ql3z7..."
    encrypted_regex: "^(password|token|secret|key|credential)$"
```

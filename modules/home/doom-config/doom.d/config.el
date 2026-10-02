;;; config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "David Szakallas"
      user-mail-address "david@szakallas.eu")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
(setq doom-font (font-spec :family "Monaco" :size 13))

;; Appearance & Theme
(setq doom-theme 'sanityinc-tomorrow-bright)

;; Display line numbers
(setq display-line-numbers-type t)

;; Use emacsclient as editor in terminals
(setenv "EDITOR" "ec")

;; Suppress native compilation warnings
(add-to-list 'warning-suppress-types '(comp))

;; Custom Flycheck local cache for chained linters (e.g. python-flake8 after LSP)
(defvar-local my/flycheck-local-cache nil)

(defun my/flycheck-checker-get (fn checker property)
  (or (alist-get property (alist-get checker my/flycheck-local-cache))
      (funcall fn checker property)))

(advice-add 'flycheck-checker-get :around 'my/flycheck-checker-get)

(add-hook 'lsp-managed-mode-hook
          (lambda ()
            (when (derived-mode-p 'python-mode)
              (setq my/flycheck-local-cache '((lsp . ((next-checkers . (python-flake8)))))))))

(after! flycheck
  (setq flycheck-check-syntax-automatically '(save)))

;; Clojure refactoring preferences
(setq cljr-favor-prefix-notation t)

;; Mouse wheel scroll amount
(setq mouse-wheel-scroll-amount '(1 ((shift) . 20)))

;; Rust mode auto-fill
(add-hook 'rust-mode-hook
          (lambda ()
            (turn-on-auto-fill)
            (set-fill-column 80)))

;; Terminal encoding setup
(defun setup-term-exec ()
  (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))

(add-hook 'term-exec-hook #'setup-term-exec)

;; Terminal key bindings
(defun bb/send-C-r ()
  (interactive)
  (term-send-raw-string "\C-r"))

(defun bb/setup-term-mode ()
  (evil-local-set-key 'insert (kbd "C-r") #'bb/send-C-r))

(add-hook 'term-mode-hook #'bb/setup-term-mode)

;; Projectile settings
(after! projectile
  (setq projectile-ignored-projects '("~/")
        projectile-create-missing-test-files t))

;; Golang formatting tool
(setq gofmt-command "gofumpt")

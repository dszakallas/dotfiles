(defconst chatgpt-shell-packages
  '(chatgpt-shell pcsv))

(defun chatgpt-shell/init-chatgpt-shell ()
  (use-package chatgpt-shell
    :ensure t))

(defun chatgpt-shell/init-pcsv ()
  (use-package pcsv
    :ensure t))

(defun chatgpt-shell/post-init-chatgpt-shell ()

  (spacemacs/declare-prefix "ac" "chat")
  (spacemacs/declare-prefix "acX" "submit")
  (spacemacs/set-leader-keys
    "acc" 'chatgpt-shell
    "acd" 'chatgpt-shell-describe-code
    "act" 'chatgpt-shell-generate-unit-test
    "acs" 'chatgpt-shell-send-region
    "acS" 'chatgpt-shell-send-and-review-region

    "acXd" 'chatgpt-shell-describe-code
    "acXi" 'chatgpt-shell-describe-image
    "acXt" 'chatgpt-shell-generate-unit-test
    "acXs" 'chatgpt-shell-send-region
    "acXS" 'chatgpt-shell-send-and-review-region
    )

  (spacemacs/declare-prefix-for-mode 'chatgpt-shell-mode "mC" "configure")
  (spacemacs/declare-prefix-for-mode 'chatgpt-shell-mode "mM" "load/save")
  (spacemacs/declare-prefix-for-mode 'chatgpt-shell-mode "mX" "submit")

  (spacemacs/set-leader-keys-for-major-mode 'chatgpt-shell-mode
    ;; navigation
    "N" 'chatgpt-shell-previous-item
    "n" 'chatgpt-shell-next-item

    ;; submissions
    "x" 'chatgpt-shell-submit
    "r" 'chatgpt-shell-refactor-code
    "XX" 'chatgpt-shell-submit
    "Xc" 'chatgpt-shell-describe-code
    "Xi" 'chatgpt-shell-describe-image
    "Xr" 'chatgpt-shell-refactor-code

    ;; save / load
    "Ms" 'chatgpt-shell-save-session-transcript
    "Ml" 'chatgpt-shell-restore-session-from-transcript


    ;; settings
    "Cp" 'chatgpt-shell-swap-system-prompt
    "CP" 'chatgpt-shell-load-awesome-prompts
    "Cm" 'chatgpt-shell-swap-model
    "C1" 'chatgpt-shell-set-as-primary-shell
    "Cr" 'chatgpt-shell-rename-buffer
    )

  )

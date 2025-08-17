;;; -*- lexical-binding: t -*-

(setq inhibit-splash-screen t)

;; set PATH
(let ((path (getenv "PATH")))
  (setenv "PATH" (concat "/opt/homebrew/bin:/Users/subwave/.local/bin/:" path))
  (setq exec-path (append exec-path '("/opt/homebrew/bin" "/Users/subwave/.local/bin/"))))

;; Command = Control
(setq mac-command-modifier 'control)

;; Disable annoying font scaling when scrolling
(global-set-key (kbd "<pinch>") 'ignore)
(global-set-key (kbd "<C-wheel-up>") 'ignore)
(global-set-key (kbd "<C-wheel-down>") 'ignore)

(when (string= system-type "darwin")
  (setq dired-use-ls-dired t
        insert-directory-program "/opt/homebrew/bin/gls"
        dired-listing-switches "-aBhl --group-directories-first"))
	  
(tool-bar-mode -1)
(toggle-scroll-bar -1)
(add-to-list 'default-frame-alist
	     '(vertical-scroll-bars . nil))
(menu-bar-mode -1)
(show-paren-mode 1)

(setq-default tab-width 4)
(setq indent-tabs-mode nil)

(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'latex-mode-hook 'display-line-numbers-mode)
(add-hook 'conf-mode-hook 'display-line-numbers-mode)

(global-hl-line-mode 1)
(visual-line-mode 1)


(set-frame-font "FiraCode Nerd Font 16" nil t)
(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font-16"))

;; (add-to-list 'major-mode-remap-alist
;; 			 '(lua-mode . lua-ts-mode))
             ;; '(c-mode . c-ts-mode)
			 ;; '(rust-mode . rust-ts-mode)
			 ;; '(python-mode . python-ts-mode))


;; Elpaca ===================
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; Packages ====================

(defvar my/keymap (make-keymap)
  "Keymap for my/mode")

(define-minor-mode my/mode
  "Minor mode for my personal keybindings."
  :init-value t
  :global t
  :keymap my/keymap)

;; The keymaps in `emulation-mode-map-alists' take precedence over
;; `minor-mode-map-alist'
(add-to-list 'emulation-mode-map-alists
             `((my/mode . ,my/keymap)))


;; Uses lexical binding to work.
(defun make-interactive (fn &rest args)
  (lambda ()
	(interactive)
	(apply 'funcall (cons fn args))))

(use-package which-key
  :config
  (which-key-mode))

(use-package ultra-scroll
  :ensure t
  :init
  (setq scroll-conservatively 3 ; or whatever value you prefer, since v0.4
        scroll-margin 0)        ; important: scroll-margin>0 not yet supported
  :config
  (ultra-scroll-mode 1))

(use-package centaur-tabs
  :ensure t :demand t
  :after (evil)
  :config
  (progn
	(centaur-tabs-mode t)
	(setq centaur-tabs-icon-type 'all-the-icons) ; or 'nerd-icons
	(setq centaur-tabs-set-icons t)
	(dolist (k '(1 2 3 4 5 6 7 8 9))
	  (evil-define-key 'normal my/keymap
		(kbd (format "C-%d" k)) (make-interactive 'centaur-tabs-select-visible-nth-tab k)))
	))

;;;; Evil =========================

(setq evil-undo-system 'undo-redo)

(use-package evil
  :ensure t :demand t
  :init (setq evil-want-keybinding nil)
  :config
  (progn
	(evil-mode 1)
	(setq evil-shift-width 4)
	(setq evil-kill-on-visual-paste nil) ; don't replace clipboard on paste in visual mode
	(evil-define-key '(normal visual) 'global
	  ";" 'evilnc-comment-or-uncomment-lines)
	(evil-define-key 'normal my/keymap
	  (kbd "C-<f11>") 'toggle-frame-fullscreen
	  (kbd "C-q") (make-interactive 'kill-this-buffer)
	  (kbd "SPC s") 'save-buffer
	  (kbd "SPC i i") (make-interactive 'find-file "~/.config/emacs/init.el"))
	;; Pasted from https://github.com/emacs-evil/evil/issues/1466#issuecomment-848638880
	(evil-define-operator black-hole-delete (beg end type)
	  "Delete text without saving it to the kill ring."
	  (interactive "<R>")
	  (evil-delete beg end type ?_))
	(evil-define-key 'normal my/keymap "d" 'black-hole-delete)
	))

(use-package evil-collection
  :ensure t :demand t
  :after (evil)
  :config (evil-collection-init))

(use-package evil-nerd-commenter
  :ensure t
  :after (evil))

;;; Completion ====================

(use-package company
  :ensure t :demand t
  :config
  (progn
	(setq company-tooltip-maximum-width 60)
	(global-company-mode)))

(use-package company-box
  :ensure t :demand t
  :after (company)
  :hook (company-mode . company-box-mode))

(use-package ivy
  :ensure t
  :config
  (progn
	(ivy-mode)
	(setopt ivy-use-virtual-buffers t)
	(setopt enable-recursive-minibuffers t)))

(use-package git-gutter
  :ensure t
  :config
  (progn
	(global-git-gutter-mode +1)))

;;;; VTERM ========================

(use-package vterm
  :ensure t
  :demand t
  :after (centaur-tabs evil)
  :config
  (progn
	(setq --vterm-visibility nil)
	(setq vterm-shell "/opt/homebrew/bin/fish")
	(evil-define-key '(insert normal) vterm-mode-map
	  (kbd "<f7>") 'hide-vterm)
	(evil-define-key 'normal my/keymap
	  (kbd "<f7>") (lambda ()
					 (interactive)
					 (if --vterm-visibility
						(hide-vterm)
					   (open-custom-vterm))))))

(defvar --vterm-visibility nil
	"Variable to track the visibility of the vterm buffer.
	When non-nil, the vterm buffer is visible; otherwise, it is hidden.")

(defun hide-vterm ()
  "Hide the vterm buffer."
  (interactive)
  (let ((window (get-buffer-window "--vterm-alpha--")))
	(when window
		(setq --vterm-visibility nil)
		(delete-window window))))

(defun open-custom-vterm ()
  "Open a new vterm buffer below."
  (interactive)
  (let* ((buffer (get-buffer-create "--vterm-alpha--"))
		 ;; Command to start tmux in the current directory
		(pwd (if (fboundp 'projectile-project-root)
				 (projectile-project-root)
			   default-directory))
		(cmd (concat "cd " pwd " && tmux\n")))
    (with-current-buffer buffer
      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode)
		(add-hook 'kill-buffer-hook
				  (lambda ()
					(interactive)
					(setq --vterm-visibility nil)
					(delete-window))
				  nil t) ;; Local to this buffer

		;; Somehow both of these are needed to disable hl-line-mode
		;; see https://www.reddit.com/r/emacs/comments/nqp1ww/comment/i0skrov/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
		(setq-local global-hl-line-mode nil)
		(hl-line-mode -1)

		(vterm-send-string cmd)
		(centaur-tabs-local-mode)))
	;; Split window and switch to vterm buffer
	(split-window-below -15)
	(other-window 1)
	(switch-to-buffer buffer)
	(setq --vterm-visibility t)))

;; Language support

(use-package lua-mode
  :ensure t
  :config
  (setq lua-indent-level 4))

(use-package rust-mode
  :ensure t)

(use-package fish-mode
  :ensure t
  :config
  (setq fish-indent-offset 4))

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-l")
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-signature-render-documentation nil)

  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
		 ;; (python-mode . lsp)
		 (lua-mode . lsp)
		 (rust-mode . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp
  :config
  (setq lsp-clients-lua-language-server-bin "/opt/homebrew/bin/lua-language-server")
  (setq lsp-clients-lua-language-server-main-location "/opt/homebrew/opt/lua-language-server/libexec/main.lua"))

(use-package lsp-pyright
  :ensure t
  :custom (lsp-pyright-langserver-command "pyright") ;; or basedpyright
  :hook (python-mode . (lambda ()
						 (require 'lsp-pyright)
						 (lsp))))  ; or lsp-deferred

(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode
  :after (lsp-ui evil)
  :config
  (progn
	;; (setq lsp-ui-sideline-show-code-actions t)
	(setq lsp-ui-doc-show-with-mouse nil)
	(setq lsp-ui-doc-position 'bottom)
	(evil-define-key 'insert my/keymap
	  (kbd "C-j") 'lsp-signature-next
	  (kbd "C-k") 'lsp-signature-previous)
	(evil-define-key 'normal my/keymap
	  (kbd "C-s") 'lsp-ivy-workspace-symbol
	  (kbd "K") 'lsp-ui-doc-glance
	  (kbd "g h") 'lsp-ui-doc-toggle
	  (kbd "<F2>") 'lsp-rename
	  (kbd "<F4>") 'lsp-execute-code-action
	  (kbd "g r") 'lsp-ui-peek-find-references
	  (kbd "g d") 'lsp-ui-peek-find-definitions)))

(use-package lsp-ivy
  :ensure t
  :commands lsp-ivy-workspace-symbol)


(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

;; Themes ===================

(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; for treemacs users
  ;; (doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  :config
  (load-theme 'doom-tomorrow-night t)
  ;; (load-theme 'doom-gruvbox t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (nerd-icons must be installed!)
  ;; (doom-themes-neotree-config)
  ;; or for treemacs users
  ;; (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; (use-package kaolin-themes
;;   :ensure t
;;   :config
;;   (load-theme 'kaolin-valley-dark t)
;;   (kaolin-treemacs-theme))

(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package projectile
  :ensure t
  :init
  (projectile-mode +1)
  :config
  (progn
	(evil-define-key 'normal my/keymap
	  (kbd "SPC p") 'projectile-command-map)))

(use-package neotree
  :ensure t
  :after (evil)
  :config
  (progn
	(setq neo-window-fixed-size nil)
	(setq neo-window-width 25)
	(setq neo-show-hidden-files t)
	(setq neo-theme (if (display-graphic-p) 'nerd-icons 'arrow))
	(evil-define-key 'normal my/keymap
	  (kbd "SPC d") 'neotree-toggle
	  (kbd "SPC p n") 'neotree-projectile-action)
	(evil-define-key 'normal neotree-mode-map
	  (kbd "a") 'neotree-create-node
	  (kbd "d") 'neotree-delete-node
	  (kbd "r") 'neotree-rename-node
	  (kbd "c") 'neotree-copy-node)))

;; (use-package dired-sidebar
;;   :ensure t
;;   :after (evil)
;;   :commands (dired-sidebar-toggle-sidebar)
;;   :init
;;   (progn
;; 	(setq dired-sidebar-width 25)
;; 	(setq dired-sidebar-theme 'nerd)
;; 	(setq dired-sidebar-use-term-integration t)
;; 	(setq dired-sidebar-subtree-line-prefix "__")
;; 	(evil-define-key 'normal 'global
;; 	  (kbd "SPC d") 'dired-sidebar-toggle-sidebar)))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 30))

(use-package copilot
  :ensure (:host github :repo "copilot-emacs/copilot.el" :branch "main")
  :after (evil)
  :hook
  (prog-mode . copilot-mode)
  (copilot-mode . (lambda ()
					(setq-local copilot--indent-warning-printed-p t)))
  :config
  (progn
	(evil-define-key 'insert my/keymap
	  (kbd "C-=") 'copilot-accept-completion)))

(use-package csv-mode
  :ensure t
  :config
  (progn
	(setq csv-separators '("," ";" "|" " " "\t"))
	(setq csv-header-lines 1)))

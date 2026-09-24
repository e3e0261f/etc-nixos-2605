# ~/nix-config/home/emacs.nix
{ config, pkgs, lib, ... }:

let
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    # 你当前用的版本（推荐 GUI）
    package = pkgs.emacs-pgtk;

    # 如果你想强制具体版本：
    # package = pkgs.emacs29-pgtk;
    # package = pkgs.emacs30-pgtk;
  };
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };

  home.file.".config/emacs/init.el".text = ''
    ; === 基础设置 ===
    (setq user-full-name "你的名字"
          user-mail-address "你@example.com"
          inhibit-startup-screen t
          ring-bell-function #'ignore
          visible-bell nil
          column-number-mode t
          show-paren-mode t
          electric-pair-mode t
          delete-selection-mode t
          global-display-line-numbers-mode t
          sentence-end-double-space nil)

    ;; === Meow 配置（Helix/Kakoune 手感）===
    (use-package meow
      :ensure t
      :init (meow-global-mode 1)
      :config
      (setq meow-use-clipboard t
            meow-cheatsheet-layout meow-cheatsheet-layout-qwerty
            meow-normal-state-cursor 'box
            meow-insert-state-cursor 'hollow
            meow-motion-state-cursor 'hollow)
      (meow-motion-state-register ?n ?e ?i ?j ?k ?l)
      (define-key meow-insert-state-key (kbd "<escape>") 'meow-normal-state)
      (meow-define-keys 'insert state '(("," . meow-prev)
                                         ("." . meow-next)
                                         ("h" . meow-left)
                                         ("j" . meow-next)
                                         ("k" . meow-prev)
                                         ("l" . meow-right)
                                         (";" . meow-left)
                                         ("'" . meow-right)
                                         ("n" . meow-next)
                                         ("e" . meow-next)
                                         ("i" . meow-prev)
                                         ("j" . meow-prev)
                                         ("k" . meow-next)
                                         ("l" . meow-next)))
      (meow-define-keys 'normal '(("?" . meow-cheatsheet)))
      (add-hook 'meow-normal-state-entry-hook #'meow--self-insert-reset))

    ;; === Magit 配置 ===
    (use-package magit
      :ensure t
      :bind (("C-x g" . magit-status)
             ("C-x G" . magit-dispatch)
             ("C-c g" . magit-file-dispatch))
      :config
      (setq magit-auto-revert-mode t
            magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
            magit-save-repository-buffers 'dontask))

    ;; === 可选扩展（推荐一起开）===
    (use-package lsp-mode
      :ensure t
      :commands lsp
      :hook ((prog-mode . lsp-deferred))
      :config (setq lsp-completion-provider :none))

    (use-package treesit-auto
      :ensure t
      :config (global-treesit-auto-mode))

    (use-package git-gutter
      :ensure t
      :config (global-git-gutter-mode))
  '';

  programs.emacs.extraConfig = ''
    (setq-default indent-tabs-mode nil
                  tab-width 2)
  '';
}

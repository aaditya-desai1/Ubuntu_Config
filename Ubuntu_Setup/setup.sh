# ----------------------------------------
# 7. Default shell (manual step)
# ----------------------------------------
if [ "$IS_CI" = true ] || [ "$IS_DOCKER_BUILD" = true ]; then
  echo "⚠️ Skipping default shell change (CI/Docker)"
else
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "ℹ️ Zsh is installed but not the default shell."
    echo "➡️ To set zsh as default, run manually:"
    echo "   chsh -s $(command -v zsh)"
    echo "   (log out and log back in afterward)"
  fi
fi

# Machine-local overrides. Not in the stow package.
# Sourced by ~/.zshrc via ~/.config/zsh/*.zsh

export GOPATH="$HOME/go"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export CUDA_HOME="/usr/local/cuda-12.9"
export ENABLE_BACKGROUND_TASKS=1
export FORCE_AUTO_BACKGROUND_TASKS=1

path=(
    "$HOME/Softwares"
    "$JAVA_HOME/bin"
    "$CUDA_HOME/bin"
    /usr/local/go/bin
    $path
)
export PATH

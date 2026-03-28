#CUDA_VISIBLE_DEVICES=1 OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=$(hostname) $HOME/data/ollama/usr/bin/ollama serve

#ROCR_VISIBLE_DEVICES=0 OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=$(hostname) $HOME/data/ollama/usr/bin/ollama serve
#HIP_VISIBLE_DEVICES=0 OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=$(hostname) $HOME/data/ollama/usr/bin/ollama serve
OLLAMA_VULKAN=1 OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=$(hostname) /usr/bin/ollama serve

import warnings
import urllib.parse

import ollama

from config import get_ollama_base_url

_selected_model: str | None = None
_warned_http: bool = False


def _client() -> ollama.Client:
    global _warned_http
    url = get_ollama_base_url()
    parsed = urllib.parse.urlparse(url)
    if (
        not _warned_http
        and parsed.scheme == "http"
        and parsed.hostname not in ("127.0.0.1", "localhost", "::1")
    ):
        _warned_http = True
        warnings.warn(
            f"Ollama URL '{url}' uses unencrypted HTTP to a non-localhost host. "
            "LLM prompts will be transmitted in cleartext. Use HTTPS for remote servers.",
            stacklevel=2,
        )
    return ollama.Client(host=url)


def list_models() -> list[str]:
    """
    Lists all models available on the local Ollama server.

    Returns:
        models (list[str]): Sorted list of model names.
    """
    response = _client().list()
    return sorted(m.model for m in response.models)


def select_model(model: str) -> None:
    """
    Sets the model to use for all subsequent generate_text calls.

    Args:
        model (str): An Ollama model name (must be already pulled).
    """
    global _selected_model
    _selected_model = model


def get_active_model() -> str | None:
    """
    Returns the currently selected model, or None if none has been selected.
    """
    return _selected_model


def generate_text(prompt: str, model_name: str = None) -> str:
    """
    Generates text using the local Ollama server.

    Args:
        prompt (str): User prompt
        model_name (str): Optional model name override

    Returns:
        response (str): Generated text
    """
    model = model_name or _selected_model
    if not model:
        raise RuntimeError(
            "No Ollama model selected. Call select_model() first or pass model_name."
        )

    response = _client().chat(
        model=model,
        messages=[{"role": "user", "content": prompt}],
    )

    return response["message"]["content"].strip()

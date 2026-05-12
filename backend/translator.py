"""
翻译模块 — 支持 Microsoft Translator / DeepL
自动检测中文跳过翻译，内置 LRU 缓存
"""
import hashlib
import os
import re
import requests
from functools import lru_cache


def _detect_contains_chinese(text: str) -> bool:
    """检测文本是否包含中文，含中文则跳过翻译"""
    return bool(re.search(r'[一-鿿]', text))


def _env(key: str, default: str = "") -> str:
    return os.environ.get(key, default).strip()


class BaseTranslator:
    def translate(self, text: str) -> str:
        raise NotImplementedError


class MicrosoftTranslator(BaseTranslator):
    """Microsoft Azure Translator (F0 免费层: 200万字符/月)"""

    def __init__(self, key: str = "", region: str = ""):
        self.key = key or _env("MS_TRANSLATOR_KEY")
        self.region = region or _env("MS_TRANSLATOR_REGION", "eastasia")
        self.endpoint = "https://api.cognitive.microsofttranslator.com"

    def translate(self, text: str) -> str:
        if not text or not text.strip():
            return text
        # 跳过已有中文的文本
        if _detect_contains_chinese(text):
            return text
        if not self.key:
            return text

        try:
            resp = requests.post(
                f"{self.endpoint}/translate?api-version=3.0&to=zh-Hans",
                headers={
                    "Ocp-Apim-Subscription-Key": self.key,
                    "Ocp-Apim-Subscription-Region": self.region,
                    "Content-Type": "application/json",
                },
                json=[{"Text": text}],
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data[0]["translations"][0]["text"]
            else:
                print(f"    [翻译] Microsoft API 错误 {resp.status_code}: {resp.text[:100]}")
                return text
        except Exception as e:
            print(f"    [翻译] 请求失败: {e}")
            return text


class DeepLTranslator(BaseTranslator):
    """DeepL API (免费层: 50万字符/月)"""

    def __init__(self, key: str = ""):
        self.key = key or _env("DEEPL_API_KEY")
        self.endpoint = "https://api-free.deepl.com/v2/translate"

    def translate(self, text: str) -> str:
        if not text or not text.strip():
            return text
        if _detect_contains_chinese(text):
            return text
        if not self.key:
            return text

        try:
            resp = requests.post(
                self.endpoint,
                data={"text": text, "target_lang": "ZH"},
                headers={"Authorization": f"DeepL-Auth-Key {self.key}"},
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["translations"][0]["text"]
            else:
                print(f"    [翻译] DeepL API 错误 {resp.status_code}: {resp.text[:100]}")
                return text
        except Exception as e:
            print(f"    [翻译] 请求失败: {e}")
            return text


# 翻译缓存（相同文本只翻译一次）
@lru_cache(maxsize=4096)
def _cached_translate(translator: BaseTranslator, text: str) -> str:
    return translator.translate(text)


def create_translator() -> BaseTranslator:
    """根据环境变量创建翻译器实例"""
    backend = _env("TRANSLATOR_API", "microsoft").lower()

    if backend == "deepl":
        key = _env("DEEPL_API_KEY")
        if key:
            print(f"[翻译] 使用 DeepL API")
            return DeepLTranslator(key)
        else:
            print("[翻译] DeepL API Key 未设置，翻译已禁用")

    elif backend == "microsoft":
        key = _env("MS_TRANSLATOR_KEY")
        if key:
            region = _env("MS_TRANSLATOR_REGION", "eastasia")
            print(f"[翻译] 使用 Microsoft Translator (区域: {region})")
            return MicrosoftTranslator(key, region)
        else:
            print("[翻译] Microsoft Translator Key 未设置，翻译已禁用")

    elif backend == "none":
        print("[翻译] 翻译功能已关闭")
    else:
        print(f"[翻译] 未知翻译后端: {backend}")

    # 未配置 API Key 时返回空翻译器（不翻译）
    return BaseTranslator()


def translate(text: str, translator: BaseTranslator = None) -> str:
    """翻译文本为中文（带缓存）"""
    if translator is None or isinstance(translator, BaseTranslator):
        return text
    if not text or not text.strip():
        return text
    return _cached_translate(translator, text)

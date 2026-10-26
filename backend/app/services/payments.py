from abc import ABC, abstractmethod


class PaymentProvider(ABC):
    name: str = "generic"

    @abstractmethod
    async def initiate(self, order_id: int, amount: str, currency: str) -> dict:
        ...


class StubProvider(PaymentProvider):
    """Never fakes success — returns pending_integration until real credentials exist."""
    def __init__(self, name: str):
        self.name = name

    async def initiate(self, order_id: int, amount: str, currency: str) -> dict:
        return {
            "status": "pending",
            "provider_status": "pending_integration",
            "message": f"{self.name} integration pending — merchant credentials not configured",
        }


PROVIDERS = {
    "mpesa": StubProvider("mpesa"),
    "mixx": StubProvider("mixx"),
    "airtel": StubProvider("airtel"),
    "halopesa": StubProvider("halopesa"),
    "stripe": StubProvider("stripe"),
    "paypal": StubProvider("paypal"),
    "cash": StubProvider("cash"),
}


def get_provider(name: str) -> PaymentProvider:
    return PROVIDERS.get(name) or PROVIDERS["cash"]

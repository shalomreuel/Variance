"""Adapter seam for an authorized future provider.

Implement the same async text(), quest(), image() methods as MockProvider.
Register it in AIGateway's server-side selection. Godot must not change.
"""


class FutureProvider:
    async def text(self, *_args, **_kwargs):
        raise NotImplementedError("Configure an authorized provider before enabling it")

    async def quest(self, *_args, **_kwargs):
        raise NotImplementedError("Configure an authorized provider before enabling it")

    async def image(self, *_args, **_kwargs):
        raise NotImplementedError("Configure an authorized provider before enabling it")

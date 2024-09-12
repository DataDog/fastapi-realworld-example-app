from pydantic import ConfigDict

from app.models.domain.rwmodel import RWModel


class RWSchema(RWModel):
    model_config = ConfigDict(from_attributes=True)

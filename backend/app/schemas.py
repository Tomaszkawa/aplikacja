from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class Priority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class Status(str, Enum):
    open = "open"
    in_progress = "in_progress"
    resolved = "resolved"


class MachineOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    location: str


class IncidentCreate(BaseModel):
    machine_id: int
    description: str = Field(min_length=3, max_length=2000)
    priority: Priority


class IncidentUpdate(BaseModel):
    status: Status


class IncidentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    machine_id: int
    description: str
    priority: Priority
    status: Status
    created_at: datetime
    updated_at: datetime

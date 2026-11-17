from datetime import datetime, timezone

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .database import Base, engine, get_db
from .models import Incident, Machine
from .schemas import IncidentCreate, IncidentOut, IncidentUpdate, MachineOut, Status

ALLOWED_TRANSITIONS = {
    Status.open: {Status.in_progress},
    Status.in_progress: {Status.resolved},
    Status.resolved: set(),
}

SEED_MACHINES = [
    {"name": "Tokarka CNC", "location": "Hala A"},
    {"name": "Prasa hydrauliczna", "location": "Hala B"},
    {"name": "Frezarka", "location": "Hala A"},
    {"name": "Robot przemysłowy", "location": "Hala C"},
]

app = FastAPI(
    title="ANDON API",
    description="System zgłaszania awarii maszyn produkcyjnych",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def seed_machines(db: Session) -> None:
    if db.query(Machine).count() == 0:
        for item in SEED_MACHINES:
            db.add(Machine(**item))
        db.commit()


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)
    db = next(get_db())
    try:
        seed_machines(db)
    finally:
        db.close()


@app.get("/machines", response_model=list[MachineOut], tags=["machines"])
def list_machines(db: Session = Depends(get_db)) -> list[Machine]:
    return db.query(Machine).order_by(Machine.id).all()


@app.get("/incidents", response_model=list[IncidentOut], tags=["incidents"])
def list_incidents(db: Session = Depends(get_db)) -> list[Incident]:
    return db.query(Incident).order_by(Incident.id.desc()).all()


@app.post(
    "/incidents",
    response_model=IncidentOut,
    status_code=status.HTTP_201_CREATED,
    tags=["incidents"],
)
def create_incident(
    payload: IncidentCreate,
    db: Session = Depends(get_db),
) -> Incident:
    machine = db.get(Machine, payload.machine_id)
    if machine is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Machine not found",
        )

    description = payload.description.strip()
    if len(description) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Description must contain at least 3 characters",
        )

    now = datetime.now(timezone.utc)
    incident = Incident(
        machine_id=payload.machine_id,
        description=description,
        priority=payload.priority.value,
        status=Status.open.value,
        created_at=now,
        updated_at=now,
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return incident


@app.patch(
    "/incidents/{incident_id}",
    response_model=IncidentOut,
    tags=["incidents"],
)
def update_incident(
    incident_id: int,
    payload: IncidentUpdate,
    db: Session = Depends(get_db),
) -> Incident:
    incident = db.get(Incident, incident_id)
    if incident is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident not found",
        )

    current = Status(incident.status)
    target = payload.status
    if target not in ALLOWED_TRANSITIONS[current]:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Status transition from '{current.value}' "
                f"to '{target.value}' is not allowed"
            ),
        )

    incident.status = target.value
    incident.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(incident)
    return incident

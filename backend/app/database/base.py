# Base class untuk semua model SQLAlchemy (declarative_base).
#
# Setiap file di app/models/ (user.py, research.py, dst) akan
# "mewarisi" Base ini, supaya SQLAlchemy tahu class Python mana yang
# merepresentasikan tabel database mana.

from sqlalchemy.orm import declarative_base

Base = declarative_base()
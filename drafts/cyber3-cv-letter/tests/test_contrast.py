import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts2"))

from check_contrast import *  # noqa: F401,F403

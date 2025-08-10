## Setup

* Get`kjv.csv` from https://openbible.com/
* Get `OpenHebrewBible-master/007-BHS-8-layer-interlinear/BHSA-8-layer-interlinear.csv` and `OpenHebrewBible-master/008-BHS-mapping-KJV/KJV-OT-mapped-to-BHS.csv` from https://github.com/eliranwong/OpenHebrewBible

## Usage

```bash
./build-big-csv-from-csv-and-kjv.sh $STRONGS_HEBREW_WORD_NUMBER
# ...where `STRONGS_HEBREW_WORD_NUMBER` is the numeric part of
# a Hebrew word number from strong's exhaustive concordance of
# the bible, e.g. `519` for H519.
```


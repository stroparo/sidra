# Executables and PATH

ignore_expr="$ZDRA_HOME/(conf|functions|templates)"

# STRONGLY RECOMMENDED munging the PATH before anything else:
pathmunge -x "${ZDRA_HOME}" $(_zdragetscriptsdirs)

pathmunge -a -i -v 'EEPATH' -x "${ZDRA_HOME}"

true

setnow () {
    # Info: Setup NOW* environment variables based on the system's date.
    export NOW_HMS="$(date '+%OH%OM%OS')"
    export NOW_ISO="$(date '+%Y-%m-%d')"
    export NOW_YMD="$(date '+%Y%m%d')"
    export NOW_YMDHM="$(date '+%Y%m%d%OH%OM')"
    export NOW_YMDHMS="$(date '+%Y%m%d%OH%OM%OS')"
}

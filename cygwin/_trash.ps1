
# this script is a disgusting hack

$Shell = new-object -comobject "Shell.Application"

function make-winpath($cygpath)
{
    $prefix = "/cygwin/"
    if($cygpath.startswith($prefix))
    {
        $partial = $cygpath.substr($prefix.length)
        $drive = $partial[0]
        $path = ($drive + ":" + $partial.substr(1))
        return $path
    }
    elseif(($cygpath[0] -ne "/") -and ($cygpath[1] -ne ":"))
    {
        return ("$PWD" + "/" + "$cygpath").replace("/", "\")
    }
    return $cygpath
}

if($args.length -gt 0)
{
    foreach($path in $args)
    {
        $native = make-winpath($path)
        $obj = $Shell.Namespace(0).ParseName($native)
        if($obj)
        {
            echo "*** path '$path' [parsed: '$native'] will be moved to trash"
            $obj.InvokeVerb("delete")
        }
        else
        {
            echo "cannot delete non-existing path '$path'"
        }
    }
}
else
{
    echo "Usage: trash <files...>"
    echo ""
    echo "Note: Automatically converts Cygwin paths to Windows paths"
}

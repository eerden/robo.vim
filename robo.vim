"--------- Robo Helper ----------

function! s:GetActivityList(manifest)"{{{
    let manifestfile = readfile(a:manifest)
    let activityFront = '' 
    let activityMiddle = ''
    let activityBack = '' 
    let activityStringList = []
    let intag = 0
    let activitylist = []
    for line in manifestfile
        "Get rid of unncecessary spaces.
        "Useful when debugging.
        let line = substitute(line, '\s\+',' ','')

        let activityFront =  matchstr(line, "<activity")
        let activityBack =  matchstr(line, "</activity>")
        if len(activityFront) > 0
            let intag = 1
        endif
        if (intag) 
            let activityMiddle = activityMiddle . line
        endif

        if len(activityBack) > 0
            let intag = 0
            let activityStringList += [activityMiddle]
            let activityMiddle = ''
        endif
    endfor
    for line in activityStringList
        let currentActivity = matchlist(line, '<activity\_.\{-}android:name="\(.\{-}\)".\{-}>')
        let activity = currentActivity[1]
        let activitylist += [substitute(activity, '^\.', '','')]
    endfor
    return activitylist
endfunction"}}}

function! s:GetActivities(manifest)"{{{
    let activities = []
    let manifestfile = readfile(a:manifest)
    for line in manifestfile
        let activitylistItem =  matchlist(line, '<activity\_.\{-}android:name="\(.\{-}\)"')
        if len(activitylistItem) > 0
            let activityName = activitylistItem[1]
            echo activityName
            let activities += [activityName]
        endif
    endfor
    return activities
endfunction"}}}

function! SetManifestFile()"{{{
    let manifest =  input("Manifest Location: ", "", "file")
    if(len(manifest) != 0)
        return manifest
    else
        echoerr "empty string"
        return null
    endif
endfunction"}}}

function! s:GetDirectories(manifest)"{{{
  let pathlen =  match(a:manifest, 'AndroidManifest.xml')  
  return strpart(a:manifest, 0, pathlen)
endfunction"}}}

function! s:OpenManifestFile()"{{{
    exec 'edit ' .  g:RoboManifestFile
endfunction"}}}

function! GetPackagePath(manifest)"{{{
    let manifestfile = readfile(a:manifest)
    for line in manifestfile
        let packagename = matchlist(line,'package="\(.\{-}\)"' )
        if len(packagename) > 0
            return substitute(packagename[1],'\.','/', 'g').'/'
        endif
    endfor
endfunction"}}}

function! GetSrcPath()"{{{
   return g:RoboProjectDir . 'src/' . GetPackagePath(g:RoboManifestFile) 
endfunction"}}}

function! s:OpenActivity(name)"{{{
    exec 'edit ' . g:RoboSrcPath. a:name . '.java'
endfunction"}}}

function! s:ListActivities(A,L,P)"{{{
    return g:RoboActivityList 
endfunction"}}}

function! s:InitRobo()"{{{
    let g:RoboManifestFile = SetManifestFile()  
    let g:RoboActivityList = s:GetActivityList(g:RoboManifestFile) 
    let g:RoboProjectDir = s:GetDirectories(g:RoboManifestFile)
    let g:RoboPackagePath = GetPackagePath(g:RoboManifestFile)
    let g:RoboSrcPath = GetSrcPath()
endfunction"}}}

"Set up vim stuff"{{{
command! -n=0 -bar RoboInit :call s:InitRobo()
command! -n=0 -bar RoboOpenManifest :call s:OpenManifestFile()
command! -n=1 -complete=customlist,s:ListActivities -bar RoboOpenActivity :call s:OpenActivity('<args>')


"}}}

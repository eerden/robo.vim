"--------- Robo ----------
"Android plugin for Vim.
function! s:GotoActivity()"{{{
    if g:RoboLoaded == 0
        echoerr "Robo not loaded!"
        return
    endif
    let currentWord =  expand('<cword>')
    let activity = substitute(currentWord, '^\.', '','')
    call s:OpenActivity(activity)
endfunction"}}}

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

function! s:SetManifestFile()"{{{
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

function! s:GetPackagePath(manifest)"{{{
    let manifestfile = readfile(a:manifest)
    for line in manifestfile
        let packagename = matchlist(line,'package="\(.\{-}\)"' )
        if len(packagename) > 0
            return substitute(packagename[1],'\.','/', 'g').'/'
        endif
    endfor
endfunction"}}}

function! s:GetSrcDir()"{{{
   return g:RoboProjectDir . 'src/' . s:GetPackagePath(g:RoboManifestFile) 
endfunction"}}}

function! s:OpenActivity(name)"{{{

    let filename =  g:RoboSrcDir. a:name . '.java'
    if filereadable(filename)
        exec 'edit ' .  filename
    else
        echohl WarningMsg |echo "No file!" | echohl Normal
    endif
endfunction"}}}

function! s:ListActivities(A,L,P)"{{{
    return filter(g:RoboActivityList, 'v:val =~? "' . a:A . '"')
endfunction"}}}

function! s:ShowActivities()"{{{
    exec 'enew'
    "call append(0,"  Select activity (<Enter> : open) | s : sorting (manifest)")
    call append(0,"  Select activity (<Enter> : open)")
    call append(1,'-----------------------------------')
    for i in range(0, len(g:RoboActivityList) - 1)
        call append(i+2, "    " . g:RoboActivityList[i])
    endfor
    setlocal buftype=nofile
    setlocal buftype=nowrite
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    setlocal nospell
    setlocal foldcolumn=0
    setlocal nomodifiable
    setlocal nonumber
    map <buffer> <cr> :RoboGoToActivity<cr>
    map <buffer> o :RoboGoToActivity<cr>
endfunction"}}}

function! s:FindRes()"{{{
    "echo matchlist(line, 'R\..\{-}\..\{-}\>')
    let word = expand('<cWORD>')
    let results =  matchlist(word, 'R\.\([a-z0-9]*\)\.\([a-z0-9_]*\)')
    if len(results) == 0
        return
    endif
    if results[1] == 'id'
        echo 'This is not happening.'
    else
        let path =  g:RoboProjectDir . 'res/' . results[1] . '/' .results[2] . '.xml'
        exec 'edit ' .path
    endif
    
endfunction"}}}

function! s:ShowEmulators()"{{{
    let avdList = []
    let avd = []
    let avdDict = {}
    exec 'enew'
    "let avds = split(system('android list avd|grep -i name'),'\n')
    let cmdResult = system('android list avd')
    call setline(1, 'List of available virtual devices:')
    call setline(2, '--------------------------------------------------------------------------------')
    let avdLines = split(cmdResult, '---------')
    for line in avdLines
        let avd= matchlist(line, 'Name: \(.\{-}\)\n\_.\{-}Target: \(.\{-}\)\n')
        let avdList += [avd]
    endfor
    for avd in avdList
        call append(2,'Name: '. avd[1]. "\t| Target: " . avd[2]) 
    endfor

    setlocal tabstop=9
    setlocal buftype=nofile
    setlocal buftype=nowrite
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    setlocal nospell
    setlocal foldcolumn=0
    setlocal nomodifiable
    setlocal nonumber
    map <buffer> <cr> :call RunEmulator()<cr>

endfunction"}}}

function! s:RunEmulator()"{{{
    let line = getline(".")    
    let match = matchlist(line, '^Name: \(.\{-}\)\s') 
    let commandString = '!emulator @' . match[1] . "&"
    exec commandString
endfunction"}}}

function! s:Init()"{{{
    let g:RoboLoaded = 1
    let g:RoboManifestFile = s:SetManifestFile()  
    let g:RoboActivityList = s:GetActivityList(g:RoboManifestFile) 
    let g:RoboProjectDir = s:GetDirectories(g:RoboManifestFile)
    let g:RoboAntBuildFile =  g:RoboProjectDir . 'build.xml'
    let g:RoboPackagePath = s:GetPackagePath(g:RoboManifestFile)
    let g:RoboSrcDir = s:GetSrcDir()
    let g:RoboResDir = g:RoboProjectDir . 'res/' 
    set makeprg=ant\ -emacs\ -find\ build.xml
    set efm=%A\ %#[javac]\ %f:%l:\ %m,%-Z\ %#[javac]\ %p^,%-C%.%#

    "Set up vim stuff"
    "Commands
    command! -n=0 -bar RoboOpenManifest :call s:OpenManifestFile()
    command! -n=1 -complete=customlist,s:ListActivities -bar RoboOpenActivity :call s:OpenActivity('<args>')
    command! -n=0 -bar RoboGoToActivity :call s:GotoActivity()
    command! -n=0 -bar RoboUnInit :call s:UnInit()
    command! -n=0 -bar RoboActivityExplorer :call s:ShowActivities()
    command! -n=0 -bar RoboFindRes :call s:FindRes()
    "Statusline
    set statusline+=%=[Robo]
endfunction"}}}

function! s:UnInit()"{{{
    unlet g:RoboLoaded
    unlet g:RoboManifestFile
    unlet g:RoboActivityList
    unlet g:RoboProjectDir
    unlet g:RoboPackagePath
    unlet g:RoboSrcDir
    unlet g:RoboResDir

    "Set up vim stuff"
    "Commands
    delcommand RoboOpenManifest
    delcommand RoboOpenActivity
    delcommand RoboGoToActivity
    delcommand RoboUnInit

    "Statusline
    set statusline-=%=[Robo]

endfunction"}}}


"Set up vim stuff"
command! -n=0 -bar RoboInit :call s:Init()
"}}}

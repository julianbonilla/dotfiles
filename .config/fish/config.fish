if status --is-interactive
    abbr --add --global yr 'cal -y'
    abbr --add --global e emacsclient
    abbr --add --global g git
    abbr --add --global gc 'git checkout'
    abbr --add --global ga 'git add -p'
    abbr --add --global gah 'git stash; and git pull --rebase; and git stash pop' 
    abbr --add --global pr 'gh pr create -t (git show -s --format=%s HEAD) -b (git show -s --format=%B HEAD | tail -n+3)'
    # abbr --add --global amz 'env AWS_SECRET_ACCESS_KEY=(pass www/aws-secret-key | head -n1)'
    abbr --add --global ais "aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | {iid: .InstanceId, type: .InstanceType, key:.KeyName, state:.State.Name, host:.PublicDnsName}'"
    abbr --add --global c clear

    if command -v exa > /dev/null
        abbr --add l exa
        abbr --add ls exa
        abbr --add ll 'exa -l'
        abbr --add lll 'exa -la'
    else
        abbr --add l ls
        abbr --add ll 'ls -l'
        abbr --add lll 'ls -la'
    end
end

# base16 themes
if status --is-interactive
    set fish_function_path $fish_function_path ~/projects/base16-fish/functions
    builtin source ~/projects/base16-fish/conf.d/base16.fish
end


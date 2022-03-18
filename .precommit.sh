cat $1 | grep -E "(ADDED|EDITED).+(.ex|.exs)$" | sed -E "s/(ADDED|EDITED)\s*//" | xargs mix format --check-formatted

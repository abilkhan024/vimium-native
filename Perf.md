??

The problem: Too slow traversal of the axui elements

1. Don't traverse multiple times, rely on push from notification
   - Keep them in some `map<uuid, custom_wrap>`
1. Don't traverse the children of interactive elements, cause homerow doesn't
   do it

??

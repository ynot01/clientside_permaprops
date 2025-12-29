# Clientside Permaprops

Since there is a limit of about 8000 entities, this sidesteps that by creating clientside entities which are not networked.

Entity data is stored in sqlite and sent to clients in a 0.02s-delayed queue, so it doesn't get near the networking limits.

<img width="966" height="329" alt="image" src="https://github.com/user-attachments/assets/cbbc206c-9bb0-4839-9678-87eca7a23fe2" />

There is still a limit of about 8000 non-networked entities, to my knowledge, and adding a lot of entities can lag clients a LOT, since these clientside props are always loaded, so don't go overboard. In the screenshot above, I would get about 30fps when looking in the direction of all 7756 props.

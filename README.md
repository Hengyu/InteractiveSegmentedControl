# InteractiveSegmentedControl
A swift implementation of a interactive segmented control effect in Apple's Music App.

In iOS 8.4, users can swipe the contents in the Music app's tableView. And the segmented control is changing smoothly while the user is scolling the content.

InteractiveSegmentedControl is a swift implementation of this effect. It is the subclass of UISegmentedControl, whith fully support for interface builder.

Jump to the demo file to see how to use it.

![Screenshot](https://raw.github.com/hengyu/InteractiveSegmentedControl/master/Screenshot/out.gif)

# Usage

```
...
let seg = InteractiveSegmentedControl(items: [AnyObject])
let swipGes = UISwipeGestureRecognize(...)
seg.interactiveGesture = swipGes
...
```

# The other

- Idea

Initialize two image views for masking. One is for start segment, the other is destination segment. Add them to each segment as subview. Change the alpha of them while the swipe gesture is recognized.

- More

After Apple released iOS 9.2, I found this feature has been removed. Maybe it is not comform to HIG to some extent :) 

# License
`InteractiveSegmentedControl` is available under the [MIT License](LICENSE).

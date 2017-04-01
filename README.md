# FURRDataSource
__Swift 3 only now! Please Read about the Swift 3 API changes and Swift 2  further down.__

a generic and robust way to drive a table view (or collection view)

You probably know the problem: Programming a table view data source and the delegate starts out easy but then you add view controller pushing and popping. You add network calls that modify cells and create more cells. Different network calls create different cells. Some cells need an explicit reload to actually do what they should do. That one coworker added a reloadData at this one line to make this esoteric edge case work without understanding why this actaully fixes the problem. 

And before you even know what hit you, you are in the deep end of inconsistencies between your data source and your table view that only happen at certain moon phases for customers with names that start with a vowel, on even numbered point releases when you scroll with the device pointed north.

You have been nodding your head, right? You know that problem, right?

Ok.

So this project tries to do help you there. The idea is that FURRDataSource keeps an array of your stuff. If you want your array content changed you give FURRDataSource a new array and it figures out all the changes and meticulously pushes those changes to the table view. Hopefully there will never be an inconsistency again. And because this can still fail with weird edge-cases I try to catch those with a long list of unit tests.

There are two catches:
1. each of your data objects must have a unique identifier
2. If your table view gets really large (several thousand cells?) FURRDataSource might get a tad slow and use quite a bit of memory.

## Swift 3 API changes and Swift 2 / 3 support going forward
If you haven't been living in a cave you will have gotten the news about Swift 3. It breaks _a lot_ of stuff if you happen to build in the wrong part of town. Which this framework does. 

The most hard hitting changes I can think of in no particular order:

* [SE-23 New API guidelines](https://github.com/apple/swift-evolution/blob/master/proposals/0023-api-guidelines.md) 
* [SE-111 the infamous "triple-one"](https://github.com/apple/swift-evolution/blob/master/proposals/0111-remove-arg-label-type-significance.md)
* [SE-86 Drop NS prefix](https://github.com/apple/swift-evolution/blob/master/proposals/0086-drop-foundation-ns.md)
* [SE-49 Move @noescape and @autoclosure to be type attributes](https://github.com/apple/swift-evolution/blob/master/proposals/0049-noescape-autoclosure-type-attrs.md)
* [SE-81 Move where clause to end of declaration](https://github.com/apple/swift-evolution/blob/master/proposals/0081-move-where-expression.md)
* [SE-46 Establish consistent label behavior across all parameters including first labels](https://github.com/apple/swift-evolution/blob/master/proposals/0046-first-label.md)

Now especially SE-46 (function labels), SE-111 and SE-23 (API guidelines) forced me to redo the complete API of FURRDataSource. Sorry for that but I'm convinced that it is now a better API.

There is two catches though: 

1. The old API is not available for Swift 3
2. The old API is available but deprecated for Swift 2

The old API will definitely go away sooner than the support for Swift 2 so do yourself a favor and update as soon as you find the time. It is mostly renames so updating shouldn't be a particularly hard task.

If you plan moving to Swift 3 update to the new API first. 

## How to Swift 3
Swift 2 is gone from the master branch as of `0.4.0`. 

__Swift 2__ remains on the `swift2` branch. If you want to still use Swift 2 configure your Cartfile to point to that branch.

__Swift 3__ is on the `master` branch. All tagged releases are Swift 3 beginning from `0.4.0`.  So you don't need to do anything.

If you have a good proposal on how to improve on that, please let me know! 

#### And as always: Bug tickets and PRs are very welcome!
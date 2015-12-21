# FURRDataSource
a generic and robust way to drive a table view

You probably know the problem: Programming a table view data source and the delegate starts out easy but then you add view controller pushing and popping. You add network calls that modify cells and create more cells. Different network calls create different cells. Some cells need an explicit reload to actually do what they should do. That one coworker added a reloadData at this one line to make this esoteric edge case work without understanding why this actaully fixes the problem. 

And before you even know what hit you, you are in the deep end of inconsistencies between your data source and your table view that only happen at certain moon phases for customers with names that start with a vowel, on even numbered point releases when you scroll with the device pointed north.

You have been nodding your head, right? You know that problem, right?

Ok.

So this project tries to do help you there. The idea is that FURRDataSource keeps an array of your stuff. If you want your array content changed you give FURRDataSource a new array and it figures out all the changes and meticulously pushes those changes to the table view. Hopefully there will never be an inconsistency again. And because this can still fail with weird edge-cases I try to catch those with a long list of unit tests.

There are two catches:
1. each of your data objects must have a unique identifier
2. If your table view gets really large (several thousand cells?) FURRDataSource might get a tad slow and use quite a bit of memory.
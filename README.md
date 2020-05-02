# Matran
A collection of functions and classes for importing Nastran bulk data and visualising results. 

**This repository is currently under development and is not ready for general use. Any feedback is much appreciated!**

## Getting Started

Either clone or download the repository and run `add_sandbox.m` to add the necessary package folders to the path.

### Prerequisites

The following MATLAB products are required to run the Matran package:

- MATLAB 9.4

### Installing as a package
**The ability to pacakge Matran as a MATLAB toolbox will be added in future releases.**
- If you wish to install Matran as a package then run `package_matran.m` to package the codebase.
- This will cause the latest version of the package to appear in the `releases` subfolder as a MATLAB package file. 
- Then install the package using the standard MATLAB process. (Apps >> Install App)

## Running the tests
Make sure you have run `add_sandbox` before attempting to run any of the tests.

- To run the core set of tests type `run_micro_tests` in the MATLAB command window.
- To run all short tests type `run_short_tests` in the MATLAB command window.
- To run all tests in the test framework type `run('TestMatran')` in the MATLAB command window. **Not reccommended** 

### Major tests

Explain what these tests test and why (TODO)

```
Give an example
```

### Coding style tests

Explain what these tests test and why (TODO)

```
Give an example
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/ChristopherSzczyglowski/Matran/blob/master/CONTRIBUTING) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/ChristopherSzczyglowski/Matran/tags). 

## Authors

* **Christopher Szczyglowski** 

See also the list of [contributors](https://github.com/ChristopherSzczyglowski/Matran/contributors) who participated in this project.

## License

This project is licensed under the Apache License - see the [LICENSE.md](https://github.com/ChristopherSzczyglowski/Matran/blob/master/LICENSE) file for details

## Acknowledgments

* Inspired by the [pyNastran](https://github.com/SteveDoyle2/pyNastran) package by Steve Doyle.

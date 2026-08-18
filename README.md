# Franka Panda ROS 1 + MoveIt Workspace

Reproducible ROS Noetic workspace for the Franka Emika Panda, including:

- ROS Noetic
- `franka_ros`
- `libfranka`
- `panda_moveit_config`
- `boost_sml`
- Gazebo Classic
- MoveIt
- Pixi-managed dependencies
- Real Panda hardware control
- MoveIt planning and execution

The workspace is designed to be reproducible across Linux x86-64 machines using a pinned `pixi.lock` and pinned Git submodules.

---

## 1. System Requirements

### Operating System

This repository targets:

- Linux x86-64
- `linux-64` Pixi platform

The tested environment uses Ubuntu with an x86-64 CPU.

Check:

```bash
uname -m
````

Expected:

```text
x86_64
```

---

## 2. Repository Structure

After cloning, the repository has the following structure:

```text
franka_panda_moveit/
├── .git/
├── .gitmodules
├── .gitignore
├── README.md
├── pixi.toml
├── pixi.lock
├── migration/
│   ├── manifest.txt
│   ├── pixi.toml
│   ├── pixi.lock
│   ├── franka_ros.patch
│   └── boost_sml.patch
├── scripts/
│   ├── bootstrap.sh
│   ├── build.sh
│   ├── build_libfranka.sh
│   └── check.sh
├── src/
│   ├── franka_ros/
│   ├── panda_moveit_config/
│   └── boost_sml/
└── third_party/
    └── libfranka/
```

The following directories are generated locally and should not be committed:

```text
.pixi/
build/
devel/
logs/
install/
```

---

# 3. Clone the Repository

Clone the repository together with all Git submodules.

```bash
git clone --recurse-submodules \
    https://github.com/Kunal-Kumar-Sahoo/franka_panda_moveit.git \
    ~/franka_panda_moveit
```

Enter the repository:

```bash
cd ~/franka_panda_moveit
```

If the repository was already cloned without `--recurse-submodules`, run:

```bash
git submodule update --init --recursive
```

Verify:

```bash
git submodule status
```

The repository currently pins:

```text
boost_sml           4c7c90eb9e6c6e476e5de88363eb9182ff4138ce
franka_ros          c11f000c2737acc22ed8dfeff40555b2644a4294
panda_moveit_config a86da56ab1c756a851d8ee2a06dd04266d1653d6
libfranka           f3b8d775a9c847cab32684c8a316f67867761674
```

`libfranka` also contains the following submodule:

```text
common              e6aa0fc210d93fe618bfd8956829a264d5476ba8
```

Verify it with:

```bash
git -C third_party/libfranka submodule status
```

---

# 4. Install Pixi

This workspace uses Pixi `0.76.2`.

Verify:

```bash
pixi --version
```

Expected:

```text
pixi 0.76.2
```

If Pixi is not installed, install it using the official Pixi installation instructions.

After installing Pixi, restart the shell if necessary and verify:

```bash
pixi --version
```

---

# 5. Create the Reproducible Environment

The environment is fully specified by:

```text
pixi.toml
pixi.lock
```

Install the environment:

```bash
cd ~/franka_panda_moveit
pixi install
```

Enter the Pixi environment:

```bash
pixi shell
```

Verify ROS:

```bash
rosversion -d
```

Expected:

```text
noetic
```

---

# 6. Verify the Toolchain

The workspace uses the Conda/Pixi compiler toolchain.

Check:

```bash
which x86_64-conda-linux-gnu-c++
```

Expected:

```text
.../.pixi/envs/default/bin/x86_64-conda-linux-gnu-c++
```

Check the compiler:

```bash
x86_64-conda-linux-gnu-c++ --version
```

The environment used for this repository currently provides GCC 15.2.

---

# 7. Apply Required Source Patches

Two small compatibility patches are maintained separately from the upstream repositories.

They are:

```text
migration/franka_ros.patch
migration/boost_sml.patch
```

Apply them using:

```bash
./scripts/bootstrap.sh
```

The script:

1. Initializes Git submodules.
2. Verifies that the patches apply.
3. Applies the `franka_ros` patch.
4. Applies the `boost_sml` patch.

Verify:

```bash
git -C src/franka_ros status --short
git -C src/boost_sml status --short
```

Expected:

```text
 M franka_hw/include/franka_hw/resource_helpers.h
 M CMakeLists.txt
```

These modifications are intentional.

---

# 8. What the Patches Do

## 8.1 `franka_ros` patch

The Franka ROS source requires `uint8_t` but does not explicitly include the corresponding standard header.

The patch adds:

```cpp
#include <cstdint>
```

to:

```text
src/franka_ros/franka_hw/include/franka_hw/resource_helpers.h
```

---

## 8.2 `boost_sml` patch

The upstream `boost_sml` package declares `roslint` as a Catkin dependency.

The current Pixi/ROS environment does not provide `roslint`, so the dependency is removed:

```cmake
find_package(catkin REQUIRED COMPONENTS
  roscpp
)
```

The `roslint_cpp()` invocation is also removed.

The package itself remains unchanged otherwise.

---

# 9. Build libfranka

`libfranka` is maintained as a Git submodule and is built from source.

First verify the repository:

```bash
git -C third_party/libfranka rev-parse HEAD
```

Expected:

```text
f3b8d775a9c847cab32684c8a316f67867761674
```

Set the Pixi compiler explicitly:

```bash
export CC="$(which x86_64-conda-linux-gnu-cc)"
export CXX="$(which x86_64-conda-linux-gnu-c++)"
```

Verify:

```bash
echo "$CC"
echo "$CXX"
```

Build:

```bash
cd ~/franka_panda_moveit/third_party/libfranka

rm -rf build
mkdir build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$CONDA_PREFIX" \
    -DEigen3_DIR="$CONDA_PREFIX/share/eigen3/cmake" \
    -DBUILD_TESTS=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
```

Build:

```bash
cmake --build . -j"$(nproc)"
```

Install into the active Pixi environment:

```bash
cmake --install .
```

---

# 10. Verify libfranka

Check:

```bash
find "$CONDA_PREFIX" \
    \( -name 'libfranka.so*' -o -name 'FrankaConfig.cmake' \) \
    -print
```

You should find:

```text
$CONDA_PREFIX/lib/libfranka.so
$CONDA_PREFIX/lib/libfranka.so.0.9
$CONDA_PREFIX/lib/libfranka.so.0.9.2
$CONDA_PREFIX/lib/cmake/Franka/FrankaConfig.cmake
```

Check runtime dependencies:

```bash
ldd "$CONDA_PREFIX/lib/libfranka.so" | grep "not found" \
    || echo "libfranka runtime: OK"
```

---

# 11. Initialize Catkin

Return to the workspace:

```bash
cd ~/franka_panda_moveit
```

Initialize Catkin:

```bash
catkin init
```

Configure the workspace:

```bash
catkin config \
    --devel-space "$PWD/devel" \
    --build-space "$PWD/build" \
    --log-space "$PWD/logs" \
    --extend "$CONDA_PREFIX" \
    --cmake-args \
        -DCMAKE_BUILD_TYPE=Release \
        -DFranka_DIR="$CONDA_PREFIX/lib/cmake/Franka" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
```

Check:

```bash
catkin config
```

Important configuration:

```text
Extending: explicit .../.pixi/envs/default
Devel Space Layout: linked
CMAKE_BUILD_TYPE=Release
Franka_DIR=.../.pixi/envs/default/lib/cmake/Franka
CMAKE_POLICY_VERSION_MINIMUM=3.5
```

---

# 12. Build the ROS Workspace

The complete workspace can be built with:

```bash
catkin build --no-status
```

For troubleshooting, it is preferable to build progressively.

## Step 1: Messages and description

```bash
catkin build franka_msgs franka_description --no-status
```

## Step 2: Hardware interface

```bash
source devel/setup.bash

catkin build franka_hw --no-status
```

## Step 3: Gazebo

```bash
catkin build franka_gazebo --no-status
```

## Step 4: Remaining Franka packages

```bash
catkin build franka_control franka_example_controllers --no-status
```

```bash
catkin build franka_visualization --no-status
```

## Step 5: Franka metapackage

```bash
catkin build franka_ros --no-status
```

## Step 6: MoveIt configuration

```bash
catkin build panda_moveit_config --no-status
```

Finally:

```bash
catkin build --no-status
```

A successful workspace should report:

```text
Failed:    None.
Abandoned: None.
```

---

# 13. Source the Workspace

After every new shell session, activate Pixi and source Catkin:

```bash
cd ~/franka_panda_moveit
pixi shell
source devel/setup.bash
```

Check:

```bash
echo "$CMAKE_PREFIX_PATH" | tr ':' '\n'
```

The workspace should appear before the Pixi environment.

---

# 14. Verify ROS Packages

Run:

```bash
rospack find franka_msgs
rospack find franka_hw
rospack find franka_control
rospack find franka_gazebo
rospack find franka_example_controllers
rospack find franka_visualization
rospack find boost_sml
rospack find panda_moveit_config
```

All should resolve to paths under:

```text
~/franka_panda_moveit/src/
```

Check versions:

```bash
rosversion franka_hw
rosversion franka_msgs
```

The expected Franka ROS package version is:

```text
0.10.1
```

---

# 15. `franka_ros` Metapackage Note

`franka_ros` is a Catkin metapackage. It does not contain nodes or libraries itself.

With the linked Catkin devel layout, it is possible for:

```bash
catkin build franka_ros
```

to succeed while:

```bash
rospack find franka_ros
```

does not resolve the package.

This does not prevent the actual Franka packages from functioning.

The functional packages are:

```text
franka_msgs
franka_hw
franka_control
franka_gazebo
franka_example_controllers
franka_visualization
```

---

# 16. Test MoveIt in Simulation

Before connecting to the physical Panda, test the complete MoveIt stack using the fake/simulation configuration.

Source the workspace:

```bash
cd ~/franka_panda_moveit
source devel/setup.bash
```

Run:

```bash
roslaunch panda_moveit_config demo.launch
```

This should start the Panda MoveIt/RViz demo.

You should be able to:

* Start RViz.
* See the Panda model.
* Interact with the MoveIt planning interface.
* Set a goal pose.
* Generate a trajectory.
* Execute the trajectory using the simulated/fake controller.

This test does **not** require the physical robot.

---

# 17. Test Gazebo

The Franka Gazebo package can also be tested independently.

The relevant launch files are located at:

```text
src/franka_ros/franka_gazebo/launch/
```

Inspect them with:

```bash
find src/franka_ros/franka_gazebo/launch \
    -maxdepth 1 \
    -type f \
    -printf '%f\n' | sort
```

Use the appropriate Franka Gazebo launch configuration for simulation.

---

# 18. Test the Real Panda

Only perform this step when the physical Panda is connected and available.

First source the environment:

```bash
cd ~/franka_panda_moveit
pixi shell
source devel/setup.bash
```

Verify libfranka:

```bash
ldd "$CONDA_PREFIX/lib/libfranka.so" | grep "not found" \
    || echo "libfranka runtime: OK"
```

Verify the control package:

```bash
rospack find franka_control
```

---

## 18.1 Launch without the Gripper

Use:

```bash
roslaunch panda_moveit_config franka_control.launch \
    robot_ip:=<PANDA_ROBOT_IP> \
    load_gripper:=false
```

Replace:

```text
<PANDA_ROBOT_IP>
```

with the IP address of the Panda controller.

---

## 18.2 Launch with the Gripper

If the Panda has the Franka gripper configured:

```bash
roslaunch panda_moveit_config franka_control.launch \
    robot_ip:=<PANDA_ROBOT_IP> \
    load_gripper:=true
```

---

# 19. What `franka_control.launch` Does

The repository's:

```text
panda_moveit_config/launch/franka_control.launch
```

performs three main operations.

First, it starts real-robot Franka control:

```xml
<include file="$(find franka_control)/launch/franka_control.launch"
         pass_all_args="true" />
```

Second, it starts ROS controllers:

```xml
<include file="$(dirname)/ros_controllers.launch"
         pass_all_args="true" />
```

Third, it starts the MoveIt configuration:

```xml
<include file="$(dirname)/demo.launch"
         pass_all_args="true">
```

with:

```xml
<arg name="load_robot_description" value="false" />
<arg name="moveit_controller_manager" value="simple" />
```

The robot description is therefore supplied by the Franka control stack rather than being loaded independently by MoveIt.

---

# 20. Recommended Real-Robot Startup Sequence

Use the following sequence for normal operation:

### Terminal 1 — Pixi + ROS environment

```bash
cd ~/franka_panda_moveit
pixi shell
source devel/setup.bash
```

### Terminal 2 — Real Panda + MoveIt

```bash
cd ~/franka_panda_moveit
pixi shell
source devel/setup.bash

roslaunch panda_moveit_config franka_control.launch \
    robot_ip:=<PANDA_ROBOT_IP> \
    load_gripper:=false
```

After the control and MoveIt systems are running, use RViz/MoveIt for planning and execution.

---

# 21. Troubleshooting

## `catkin: command not found`

Make sure the Pixi environment is active:

```bash
cd ~/franka_panda_moveit
pixi shell
```

Then:

```bash
which catkin
```

---

## `libfranka.so` not found

Check:

```bash
find "$CONDA_PREFIX" \
    -name 'libfranka.so*' \
    -print
```

If nothing is found, rebuild and install libfranka:

```bash
cd third_party/libfranka/build
cmake --build . -j"$(nproc)"
cmake --install .
```

---

## `FrankaConfig.cmake` not found

Check:

```bash
find "$CONDA_PREFIX" \
    -name 'FrankaConfig.cmake' \
    -print
```

It should be:

```text
$CONDA_PREFIX/lib/cmake/Franka/FrankaConfig.cmake
```

Make sure Catkin was configured with:

```bash
-DFranka_DIR="$CONDA_PREFIX/lib/cmake/Franka"
```

---

## `franka_msgsConfig.cmake` not found

Build and source the workspace:

```bash
catkin build franka_msgs --no-status
source devel/setup.bash
```

Then:

```bash
rospack find franka_msgs
```

---

## `gazebo_ros_control` not found

Make sure the Pixi environment contains:

```bash
pixi list | grep gazebo
```

The workspace requires the ROS Noetic Gazebo packages specified in `pixi.toml`.

---

## `boost_sml` not found

Build it:

```bash
catkin build boost_sml --no-status
```

Then:

```bash
source devel/setup.bash
rospack find boost_sml
```

If CMake reports a missing `roslint` dependency, make sure the migration patch has been applied:

```bash
git -C src/boost_sml diff
```

The `roslint` dependency should have been removed.

---

## `franka_ros` not found by `rospack`

`franka_ros` is a metapackage. Verify the functional packages instead:

```bash
rospack find franka_hw
rospack find franka_control
rospack find franka_msgs
rospack find franka_gazebo
```

If those resolve correctly, the Franka stack itself is available.

---

## Patch does not apply

If:

```bash
./scripts/bootstrap.sh
```

reports that a patch does not apply, check:

```bash
git -C src/franka_ros status --short
git -C src/boost_sml status --short
```

If the modifications already exist, the patch has already been applied.

Do not use:

```bash
git reset --hard
```

unless you intentionally want to discard the local compatibility modifications.

---

# 22. Reproducibility

The environment is intentionally pinned.

The important reproducibility files are:

```text
pixi.toml
pixi.lock
.gitmodules
```

The source repositories are pinned as Git submodules.

Check all pinned revisions:

```bash
git submodule status

git -C src/franka_ros rev-parse HEAD
git -C src/panda_moveit_config rev-parse HEAD
git -C src/boost_sml rev-parse HEAD
git -C third_party/libfranka rev-parse HEAD
git -C third_party/libfranka submodule status
```

The `pixi.lock` file should not be regenerated unnecessarily.

For a clean reproduction:

```bash
git clone --recurse-submodules \
    https://github.com/Kunal-Kumar-Sahoo/franka_panda_moveit.git \
    ~/franka_panda_moveit

cd ~/franka_panda_moveit

pixi install
pixi shell

./scripts/bootstrap.sh
```

Then build `libfranka`, configure Catkin, and build the workspace as described above.

---

# 23. Updating Dependencies

Do not update the following casually:

```text
franka_ros
libfranka
boost_sml
panda_moveit_config
ROS Noetic dependencies
```

The current repository represents a validated combination of versions.

If dependencies need to be upgraded:

1. Create a separate branch.
2. Update the relevant submodule.
3. Update `pixi.toml` if necessary.
4. Regenerate `pixi.lock` only when required.
5. Reapply/update compatibility patches.
6. Rebuild the complete workspace.
7. Test MoveIt simulation.
8. Test the real Panda.
9. Only then update the pinned baseline.

---

# 24. Clean Rebuild

If Catkin gets into an inconsistent state, remove only generated build artifacts:

```bash
cd ~/franka_panda_moveit

rm -rf build devel logs
```

Then reconfigure:

```bash
catkin init
```

```bash
catkin config \
    --devel-space "$PWD/devel" \
    --build-space "$PWD/build" \
    --log-space "$PWD/logs" \
    --extend "$CONDA_PREFIX" \
    --cmake-args \
        -DCMAKE_BUILD_TYPE=Release \
        -DFranka_DIR="$CONDA_PREFIX/lib/cmake/Franka" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
```

Then rebuild:

```bash
catkin build --no-status
```

Do **not** delete `.pixi/` unless you intentionally want to recreate the Pixi environment.

---

# 25. Quick Start

For a machine that already has Pixi installed:

```bash
git clone --recurse-submodules \
    https://github.com/Kunal-Kumar-Sahoo/franka_panda_moveit.git \
    ~/franka_panda_moveit

cd ~/franka_panda_moveit

pixi install
pixi shell

./scripts/bootstrap.sh

export CC="$(which x86_64-conda-linux-gnu-cc)"
export CXX="$(which x86_64-conda-linux-gnu-c++)"

cd third_party/libfranka

rm -rf build
mkdir build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$CONDA_PREFIX" \
    -DEigen3_DIR="$CONDA_PREFIX/share/eigen3/cmake" \
    -DBUILD_TESTS=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5

cmake --build . -j"$(nproc)"
cmake --install .

cd ~/franka_panda_moveit

catkin init

catkin config \
    --devel-space "$PWD/devel" \
    --build-space "$PWD/build" \
    --log-space "$PWD/logs" \
    --extend "$CONDA_PREFIX" \
    --cmake-args \
        -DCMAKE_BUILD_TYPE=Release \
        -DFranka_DIR="$CONDA_PREFIX/lib/cmake/Franka" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5

catkin build --no-status

source devel/setup.bash

roslaunch panda_moveit_config demo.launch
```

For the real Panda:

```bash
source ~/franka_panda_moveit/devel/setup.bash

roslaunch panda_moveit_config franka_control.launch \
    robot_ip:=<PANDA_ROBOT_IP> \
    load_gripper:=false
```

---

# 26. Validated Migration

This repository has been validated by reproducing the complete software stack on a second machine.

Validation covers:

```text
Git submodules             ✓
Pixi environment           ✓
ROS Noetic                 ✓
libfranka                  ✓
Franka ROS                 ✓
boost_sml                  ✓
Gazebo                     ✓
MoveIt                     ✓
Panda MoveIt simulation    ✓
Real Panda connection      ✓
Real Panda MoveIt control  ✓
```

The repository therefore serves as the reproducible baseline for the Franka Panda ROS 1 + MoveIt environment.

````

### One change I strongly recommend

The current `scripts/bootstrap.sh` is useful, but **it does not build libfranka or Catkin**. For a genuinely one-command setup, I'd make the scripts form a clean progression:

```text
bootstrap.sh
    ↓
build_libfranka.sh
    ↓
build.sh
    ↓
check.sh
````

Then the README's quick start can eventually become just:

```bash
git clone --recurse-submodules \
    https://github.com/Kunal-Kumar-Sahoo/franka_panda_moveit.git \
    ~/franka_panda_moveit

cd ~/franka_panda_moveit
pixi install
pixi shell

./scripts/bootstrap.sh
./scripts/build_libfranka.sh
./scripts/build.sh
./scripts/check.sh

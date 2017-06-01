#!/bin/bash

# @author Pavel Ruban
# @contact www.pavelruban.org

# Use lazy arguments strategy - if user doesn't pass any arguments we use default values defined in this file,
# if user passes some args we override this file with given values & re execute it with empty args, so next
# time if user doesn't need to change arg he/she can just run command without any args, or to specify only
# some of them, e.g. for current program the most often changed argument is W (radial speed), while Wn & Ts
# (no load max speed & stall torque) usually are static for given DC motor, so we use args order consder
# argument change frequently i.e. W Wn Ts.
if [ $# -gt 0 ]
	then
		if [ ! -z $1 ]; then
			perl -pi -e "s/: \\$\{W:=.*?\}/: \\$\{W:=$1}/g" ${BASH_SOURCE[0]}
		fi


		if [ ! -z $2 ]; then
			perl -pi -e "s/: \\$\{Wn:=.*?\}/: \\$\{Wn:=$2}/g" ${BASH_SOURCE[0]}
		fi

		if [ ! -z $3 ]; then
			perl -pi -e "s/: \\$\{Ts:=.*?\}/: \\$\{Ts:=$3}/g" ${BASH_SOURCE[0]}
		fi

		# Evaluate change file without args & exit, no need for endless recursion here.
		eval ${BASH_SOURCE[0]}; exit;
else
	usage="$(basename "$0") [-h] Ts W Wn -- program to calculate torque of the DC motor for rated speed

	where:
	    -h  show this help text
	    Ts	stall torque N * m
	    W	given speed in RPM
	    Wn	no load speed in RPM (the maximum output speed of the motor)"

	while getopts ':h:' option; do
	  case "$option" in
	    h) echo "$usage"
	       exit
	       ;;

	    :) printf "missing argument for -%s\n" "$OPTARG" >&2
	       echo "$usage" >&2
	       exit 1
	       ;;

	   \?) printf "\nillegal option: -%s\n\n" "$OPTARG" >&2
	       echo "$usage" >&2
	       exit 1
	       ;;
	  esac
	done

	shift $((OPTIND - 1))

	# These default args are dynamically changed over time.
	: ${W:=2000}
	: ${Wn:=3500}
	: ${Ts:=0.65}

	printf "W = $W Wn = $Wn Ts = $Ts\n\n"

	cat <<EOF | calc -q -s -f /dev/stdin
#!/usr/bin/calc -q -s -f
RPM = $W;
RPM_MAX = $Wn;
Ts = $Ts;

## Calculates angular speed (radians per second) from RPM.
define W(rpm) {
	local rps = rpm / 60;
	local radians_per_revolution = 2 * pi();

	return radians_per_revolution * rps;
}

## Torque equation for typical DC brushed motor.
define T(rpm) {
	return Ts - (W(rpm) * Ts) / W(RPM_MAX);
}

print "\nBrushed DC motor torque at given params:";
print "---------------------------------------------------------------------------------------";
print "RPM:", RPM, "\t\t\t\t# Revolutions per minute";
print "RPS:", RPM / 60, "\t\t# Revolutions per second";
print;
print "RPR:", 2 * pi(), "\t\t# Radians per revolution";
print;
print "W:", W(RPM), "\t\t# Angular velocity in radians per second";
print "Wn:", W(RPM_MAX), "\t\t# Maximum no load angular velocity";
print "Ts:", Ts, "\t\t\t\t# Stall torque of the given DC motor";
print "--------------------------------------------------------------------------------------";
print "equals to"
print "======================================================================================";
print "\t", T(RPM), "\t# Newtons per meter";
print "======================================================================================";

exit;
EOF

fi

#! /bin/bash
TARGET_FILE=$1
SRC_LIST=$(for i in ${LIB_SRCS}; do
    echo ${i}|${SED} "s:${TOP_DIR}:    \${PROJECT_SOURCE_DIR}:g"
done)

rm -f ${TARGET_FILE}

cat << EOB >> ${TARGET_FILE}
$(for i in ${INTERNAL_INCLUDES} ${EXTERNAL_INCLUDES}; do
    echo $i \
        | ${SED} "s:-I${TOP_DIR}\(.*\):INCLUDE_DIRECTORIES (\${PROJECT_SOURCE_DIR}\1):g"
done)

EOB

if echo ${COMP_LIB_COMPONENTS} | grep -qw ${MODULE_NAME}; then
    TYPE="OBJECT"
else
    TYPE="STATIC"
fi

if [ "${LIBA_TARGET}" != "" ]; then
    LNAME=${LIBA_TARGET#lib}
    LNAME=${LNAME%.a}

    cat << EOB >> ${TARGET_FILE}
ADD_LIBRARY (${LNAME} ${TYPE}
${SRC_LIST}
)

EOB
fi

TARGET_COUNT=$(echo "${TARGET}" | awk '{ print NF }')


if (( TARGET_COUNT == 1 )); then
    cat << EOB >> ${TARGET_FILE}
ADD_EXECUTABLE (${TARGET}
$(for i in ${SRCS}; do
    echo ${i} | ${SED} "s:${TOP_DIR}:    \${PROJECT_SOURCE_DIR}:g"
done)
)

$(for i in \
    $(echo ${LDFLAGS} | grep -o '\-l[^ ]*' | sort -u | sed 's:^-l::g'); do
        echo "TARGET_LINK_LIBRARIES (${TARGET} ${i})"
done)

EOB
fi

if (( TARGET_COUNT > 1 )); then
    cat << EOB >> ${TARGET_FILE}
$(for i in ${TARGET}; do
    echo "ADD_EXECUTABLE (${i} "

    j=${i//-/_}
    k=$(eval echo '${''SRCS_'"${j}"'}')

    for v in ${k}; do
        echo "    ${v}"
    done
    echo ")"
done)

$(for i in ${TARGET}; do
    echo "TARGET_LINK_LIBRARIES (${i} ${COMP_LIB_NAME})"
    for j in $(echo ${LDFLAGS} | grep -o '\-l[^ ]*' | sort -u | sed 's:^-l::g' | grep -vw ${COMP_LIB_NAME}); do
        echo "TARGET_LINK_LIBRARIES (${i} ${j})"
    done
    echo ""
done)

EOB

fi
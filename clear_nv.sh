#!/bin/bash

tpmnv_relindex -p $1 -i 0x20000001
tpmnv_relindex -p $1 -i 0x20000002
tpmnv_relindex -p $1 -i owner

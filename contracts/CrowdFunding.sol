// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

contract CrowdFunding {
    // 捐助人结构定义
    struct Funder {
        address payable addr; // 捐助人的地址
        uint256 amount; // 出资数额
    }

    

    // 资金使用请求结构定义
    struct Use {
        string info; // 使用请求的说明
        uint256 goal; // 使用请求的数额
        uint256 agreeAmount; // 目前的同意数额
        uint256 disagree; // 目前的不同意数额
        bool over; // 请求是否结束
        mapping(uint256 => uint256) agree; // 出资人是否同意 0: 还没决定，1：同意，2：不同意
    }



    // 证明人请求结构定义
    struct Prove {
        string info; // 证明的说明
        string relation; // 关系
        string picture; // 证明图片
    }

    // 筹款项目的结构定义
    struct Funding {
        address payable initiator; // 发起人
        string title; // 项目标题
        string info; // 项目简介
        string coverImage; //封面图
        string[] details; // 详情图片
        uint256 goal; // 目标金额
        uint256 endTime; // 筹款结束时间
        bool success; // 筹款是否成功，成功则 amount 含义为项目剩余的钱
        uint256 amount; // 当前已经筹集到的金额
        uint256 numFunders; // 捐助记录数量
        uint256 numUses; // 使用请求数量
        uint256 numProves;
        mapping(uint256 => Funder) funders; // 捐助记录具体信息
        mapping(uint256 => Use) uses; // 所有的使用请求
        mapping(uint256 => Prove) proves;
    }

    uint256 public numFundings; // 筹款项目数量
    mapping(uint256 => Funding) public fundings; // 所有的筹款项目

    /**
     * 发起筹款项目
     * @param initiator 发起人
     * @param title 项目标题
     * @param info 项目简介
     * @param goal 目标金额
     * @param endTime 结束时间
     */
    function newFunding(
        address payable initiator,
        string memory title,
        string memory info,
        string memory coverImage,
        string[] memory details,
        uint256 goal,
        uint256 endTime
    ) public returns (uint256) {
        require(endTime > block.timestamp);

        numFundings = numFundings + 1;
        Funding storage f = fundings[numFundings];
        f.initiator = initiator;
        f.title = title;
        f.coverImage = coverImage;
        f.details = details;
        f.info = info;
        f.goal = goal;
        f.endTime = endTime;
        f.success = false;
        f.amount = 0;
        f.numFunders = 0;
        f.numUses = 0;
        f.numProves = 0;

        return numFundings;
    }

    function contribute(uint256 ID) public payable {
        // 贡献的钱必须大于0，不能超过差额
        require(
            msg.value > 0 &&
                msg.value <= fundings[ID].goal - fundings[ID].amount
        );
        // 时间上必须还没结束
        require(fundings[ID].endTime > block.timestamp);
        // 必须是未完成的筹款
        require(fundings[ID].success == false);

        Funding storage f = fundings[ID];
        f.amount += msg.value;
        f.numFunders = f.numFunders + 1;
        f.funders[f.numFunders].addr = msg.sender;
        f.funders[f.numFunders].amount = msg.value;
        // 考虑本项目是否达成目标
        f.success = f.amount >= f.goal;
    }

    // 退钱
    function returnMoney(uint256 ID) public {
        require(ID <= numFundings && ID >= 1);
        require(fundings[ID].success == false);

        Funding storage f = fundings[ID];
        for (uint256 i = 1; i <= f.numFunders; i++)
            if (f.funders[i].addr == msg.sender) {
                f.funders[i].addr.transfer(f.funders[i].amount);
                f.funders[i].amount = 0;
                f.amount -= f.funders[i].amount;
            }
    }

    function newUse(
        uint256 ID,
        uint256 goal,
        string memory info
    ) public {
        require(ID <= numFundings && ID >= 1);
        require(fundings[ID].success == true);
        require(goal <= fundings[ID].amount);
        require(msg.sender == fundings[ID].initiator);

        Funding storage f = fundings[ID];
        f.numUses = f.numUses + 1;
        f.uses[f.numUses].info = info;
        f.uses[f.numUses].goal = goal;
        f.uses[f.numUses].agreeAmount = 0;
        f.uses[f.numUses].disagree = 0;
        f.uses[f.numUses].over = false;
        f.amount = f.amount - goal;
    }

    function newProve(
        uint256 ID,
        string memory info,
        string memory relation,
        string memory picture
    ) public {
        require(ID <= numFundings && ID >= 1);
        require(msg.sender != fundings[ID].initiator);

        Funding storage f = fundings[ID];
        f.numProves = f.numProves + 1;
        f.proves[f.numProves].info = info;
        f.proves[f.numProves].relation = relation;
        f.proves[f.numProves].picture = picture;
    }

    function agreeUse(
        uint256 ID,
        uint256 useID,
        bool agree
    ) public {
        require(ID <= numFundings && ID >= 1);
        require(useID <= fundings[ID].numUses && useID >= 1);
        require(fundings[ID].uses[useID].over == false);

        for (uint256 i = 1; i <= fundings[ID].numFunders; i++)
            if (fundings[ID].funders[i].addr == msg.sender) {
                if (fundings[ID].uses[useID].agree[i] == 1) {
                    fundings[ID].uses[useID].agreeAmount -= fundings[ID]
                        .funders[i]
                        .amount;
                } else if (fundings[ID].uses[useID].agree[i] == 2) {
                    fundings[ID].uses[useID].disagree -= fundings[ID]
                        .funders[i]
                        .amount;
                }
                if (agree) {
                    fundings[ID].uses[useID].agreeAmount += fundings[ID]
                        .funders[i]
                        .amount;
                    fundings[ID].uses[useID].agree[i] = 1;
                } else {
                    fundings[ID].uses[useID].disagree += fundings[ID]
                        .funders[i]
                        .amount;
                    fundings[ID].uses[useID].agree[i] = 2;
                }
            }
        checkUse(ID, useID);
    }

    function checkUse(uint256 ID, uint256 useID) public {
        require(ID <= numFundings && ID >= 1);
        require(fundings[ID].uses[useID].over == false);

        if (fundings[ID].uses[useID].agreeAmount >= fundings[ID].goal / 2) {
            fundings[ID].uses[useID].over = true;
            fundings[ID].initiator.transfer(fundings[ID].uses[useID].goal);
        }
        if (fundings[ID].uses[useID].disagree > fundings[ID].goal / 2) {
            fundings[ID].amount =
                fundings[ID].amount +
                fundings[ID].uses[useID].goal;
            fundings[ID].uses[useID].over = true;
        }
    }

    function getUseLength(uint256 ID) public view returns (uint256) {
        require(ID <= numFundings && ID >= 1);

        return fundings[ID].numUses;
    }

    function getProveLength(uint256 ID) public view returns (uint256) {
        require(ID <= numFundings && ID >= 1);

        return fundings[ID].numProves;
    }

    function getDetails(uint256 ID) public view returns (string[] memory) {
        require(ID <= numFundings && ID >= 1);

        return fundings[ID].details;
    }

    function getUse(
        uint256 ID,
        uint256 useID,
        address addr
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        require(ID <= numFundings && ID >= 1);
        require(useID <= fundings[ID].numUses && useID >= 1);

        Use storage u = fundings[ID].uses[useID];
        uint256 agree = 0;
        for (uint256 i = 1; i <= fundings[ID].numFunders; i++)
            if (fundings[ID].funders[i].addr == addr) {
                agree = fundings[ID].uses[useID].agree[i];
                break;
            }
        return (u.info, u.goal, u.agreeAmount, u.disagree, u.over, agree);
    }

    function getProve(uint256 ID, uint256 useID)
        public
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        require(ID <= numFundings && ID >= 1);

        Prove storage u = fundings[ID].proves[useID];
        return (u.info, u.relation, u.picture);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyFundings(address addr, uint256 ID)
        public
        view
        returns (uint256)
    {
        uint256 res = 0;
        for (uint256 i = 1; i <= fundings[ID].numFunders; i++) {
            if (fundings[ID].funders[i].addr == addr)
                res += fundings[ID].funders[i].amount;
        }
        return res;
    }
}
